use anyhow::Result;
use clap::{Args, Parser, Subcommand};
use serde::Deserialize;
use ssh2::Session;
use std::net::TcpStream;
use std::path::PathBuf;
use std::thread::{self, JoinHandle};
use std::time::Duration;
use std::{io::prelude::*, path::Path};
use tracing::*;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

const PREPARE_COMMANDS: [&'static str; 2] = ["whoami", "sudo rm -f *.tar"];
const COMMIT_COMMANDS: [&'static str; 1] = ["sudo mv *.tar /tmp/incoming-stacks"];

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Args)]
pub struct Deploy {
    #[arg(long, value_name = "FILE")]
    terraform: PathBuf,
    #[arg(long, value_name = "FILE")]
    cert: PathBuf,
    #[arg(long, value_name = "FILE")]
    archive: PathBuf,
    #[arg(long)]
    poll: Option<String>,
    #[arg(long)]
    prepare_only: bool,
}

#[derive(Subcommand)]
enum Commands {
    Deploy(Deploy),
}

fn get_rust_log() -> String {
    std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into())
}

#[derive(Clone)]
struct Executor {
    cert: PathBuf,
    port: usize,
}

impl Executor {
    fn execute(&self, server: &Server, command: &str) -> Result<()> {
        let tcp = TcpStream::connect(format!("{}:{}", server.ip, self.port))?;
        let mut sess = Session::new()?;
        sess.set_tcp_stream(tcp);
        sess.handshake()?;
        sess.userauth_pubkey_file(&server.user, None, &self.cert, None)?;

        let mut channel = sess.channel_session()?;
        channel.exec(command)?;
        let mut s = String::new();
        channel.read_to_string(&mut s)?;
        if !s.is_empty() {
            info!("{} '{}' = {}", &server.ip, command, s.trim());
        } else {
            info!("{} '{}'", &server.ip, command);
        }

        channel.wait_close()?;
        trace!("{}", channel.exit_status()?);

        Ok(())
    }

    fn scp(&self, server: &Server, file: &Path) -> Result<()> {
        let tcp = TcpStream::connect(format!("{}:22", server.ip))?;
        let mut sess = Session::new()?;
        sess.set_tcp_stream(tcp);
        sess.handshake()?;
        sess.userauth_pubkey_file(&server.user, None, &self.cert, None)?;

        let file_name = file.file_name().unwrap();
        let file_meta = file.metadata()?;

        info!(
            "{} copying {} bytes to {}",
            &server.ip,
            file_meta.len(),
            file_name.to_str().unwrap()
        );

        let mut copying = std::fs::File::open(file)?;
        let mut remote_file = sess.scp_send(Path::new(file_name), 0o644, file_meta.len(), None)?;
        std::io::copy(&mut copying, &mut remote_file)?;
        remote_file.send_eof()?;
        remote_file.wait_eof()?;
        remote_file.close()?;
        remote_file.wait_close()?;

        Ok(())
    }
}

trait Step {
    fn run(&self) -> Result<()>;
}

struct PrepareStep {
    exec: Executor,
    server: Server,
    archive: PathBuf,
}

impl Step for PrepareStep {
    fn run(&self) -> Result<()> {
        for command in PREPARE_COMMANDS {
            self.exec.execute(&self.server, command)?;
        }
        self.exec.scp(&self.server, &self.archive)?;

        Ok(())
    }
}

struct CommitStep {
    exec: Executor,
    server: Server,
}

impl Step for CommitStep {
    fn run(&self) -> Result<()> {
        for command in COMMIT_COMMANDS {
            self.exec.execute(&self.server, command)?;
        }

        Ok(())
    }
}

struct VerifyStep {
    server: Server,
}

impl Step for VerifyStep {
    fn run(&self) -> Result<()> {
        let url = format!("http://{}:7000/status", self.server.ip);
        let poller = Poller::new(self.server.ip.clone(), url);

        match poller.run() {
            Ok(polled) => {
                info!("{} {:?}", &self.server.ip, polled);

                Ok(())
            }
            Err(e) => Err(e),
        }
    }
}

fn run_all<T: Step + Send + Sync + 'static>(steps: Vec<T>) -> Vec<JoinHandle<Result<()>>> {
    steps
        .into_iter()
        .map(|step| thread::spawn(move || step.run()))
        .collect::<Vec<_>>()
}

fn join_all(handles: Vec<JoinHandle<Result<()>>>) -> Result<Vec<Result<()>>> {
    handles
        .into_iter()
        .map(|j| j.join().map_err(|e| anyhow::anyhow!("{:?}", e)))
        .collect::<Result<Vec<_>>>()
}

fn run_and_join_all<T: Step + Send + Sync + 'static>(steps: Vec<T>) -> Result<Vec<Result<()>>> {
    join_all(run_all(steps))
}

fn main() -> Result<()> {
    tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(get_rust_log()))
        .with(tracing_subscriber::fmt::layer().with_thread_ids(false))
        .init();

    let cli = Cli::parse();

    match cli.command {
        Commands::Deploy(deploy) => {
            let terraform = std::fs::File::open(&deploy.terraform)?;
            let env: Environment = serde_json::from_reader(terraform)?;

            let exec = Executor {
                cert: deploy.cert.clone(),
                port: 22,
            };

            let servers = env.servers.value;

            let preparations = servers
                .iter()
                .map(|server| PrepareStep {
                    exec: exec.clone(),
                    server: server.clone(),
                    archive: deploy.archive.clone(),
                })
                .collect::<Vec<_>>();

            info!("preparing");

            let joined = run_and_join_all(preparations);

            info!("prepare = {:?}", joined);

            let commits = servers
                .iter()
                .map(|server| CommitStep {
                    exec: exec.clone(),
                    server: server.clone(),
                })
                .collect::<Vec<_>>();

            let verify = servers
                .iter()
                .map(|server| VerifyStep {
                    server: server.clone(),
                })
                .collect::<Vec<_>>();

            let verify = run_all(verify);

            if !deploy.prepare_only {
                info!("committing");

                let joined = run_and_join_all(commits);

                info!("commit = {:?}", joined);
            } else {
                info!("prepare-only");
            }

            let joined = join_all(verify);

            info!("verify = {:?}", joined);
        }
    }

    Ok(())
}

#[derive(Deserialize)]
struct Environment {
    servers: ServersDef,
}

#[derive(Deserialize)]
struct ServersDef {
    value: Vec<Server>,
}

#[allow(dead_code)]
#[derive(Deserialize, Clone, Debug)]
struct Server {
    id: String,
    ip: String,
    key: String,
    #[serde(rename = "sshAt")]
    ssh_at: String,
    user: String,
}

#[derive(Debug)]
enum Polled {
    Modified(Status),
    Unchanged(Status),
}

struct Poller {
    prefix: String,
    url: String,
}

impl Poller {
    fn new(prefix: String, url: String) -> Self {
        Self { prefix, url }
    }

    fn run(&self) -> Result<Polled> {
        let initial = self.once()?;

        for _n in 1..120 {
            thread::sleep(Duration::from_secs(1));

            match self.once() {
                Ok(latest) => {
                    info!(tag = latest.tag, hash = latest.git.hash, "{}", &self.prefix);

                    if initial.git.hash != latest.git.hash {
                        return Ok(Polled::Modified(latest));
                    }
                }
                Err(e) => {
                    warn!("poll error {:?}", e);
                }
            }
        }

        Ok(Polled::Unchanged(initial))
    }

    fn once(&self) -> Result<Status> {
        Ok(reqwest::blocking::get(&self.url)?.json::<Status>()?)
    }
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
struct Status {
    server_name: String,
    version: String,
    tag: String,
    name: String,
    git: Git,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
struct Git {
    hash: String,
}

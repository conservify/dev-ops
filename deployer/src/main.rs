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

#[derive(Debug, Args)]
pub struct Poll {
    #[arg(long)]
    url: String,
}

#[derive(Subcommand)]
enum Commands {
    Deploy(Deploy),
    Poll(Poll),
}

fn get_rust_log() -> String {
    std::env::var("RUST_LOG").unwrap_or_else(|_| "info".into())
}

#[derive(Clone)]
struct Executor {
    cert: PathBuf,
}

impl Executor {
    fn execute(&self, server: &Server, command: &str) -> Result<()> {
        let tcp = TcpStream::connect(format!("{}:22", server.ip))?;
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

fn run_all<T: Step + Send + Sync + 'static>(steps: Vec<T>) -> Vec<JoinHandle<Result<()>>> {
    steps
        .into_iter()
        .map(|step| thread::spawn(move || step.run()))
        .collect::<Vec<_>>()
}

fn run_and_join_all<T: Step + Send + Sync + 'static>(steps: Vec<T>) -> Result<Vec<Result<()>>> {
    run_all(steps)
        .into_iter()
        .map(|j| j.join().map_err(|e| anyhow::anyhow!("{:?}", e)))
        .collect::<Result<Vec<_>>>()
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

            info!("{:?}", joined);

            let commits = servers
                .iter()
                .map(|server| CommitStep {
                    exec: exec.clone(),
                    server: server.clone(),
                })
                .collect::<Vec<_>>();

            if !deploy.prepare_only {
                info!("committing");

                let poller = deploy.poll.map(|url| Poller::new(url.clone()));
                let poller = thread::spawn(move || match poller {
                    Some(poller) => poller.run(),
                    None => Ok(None),
                });

                let joined = run_and_join_all(commits);

                info!("{:?}", joined);

                let polled = poller.join().map_err(|e| anyhow::anyhow!("{:?}", e))?;

                info!("{:?}", polled);
            }
        }
        Commands::Poll(poll) => {
            let poller = Poller::new(poll.url.clone());

            poller.once()?;
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

struct Poller {
    url: String,
}

impl Poller {
    fn new(url: String) -> Self {
        Self { url }
    }

    fn run(&self) -> Result<Option<Status>> {
        let initial = self.once()?;

        let mut error = false;

        for _n in 1..120 {
            thread::sleep(Duration::from_secs(1));

            match self.once() {
                Ok(latest) => {
                    if initial.git.hash != latest.git.hash {
                        return Ok(Some(latest));
                    } else {
                        if error {
                            return Err(anyhow::anyhow!(
                                "Git hash unchanged after error, assuming same version."
                            ));
                        }
                    }
                }
                Err(e) => {
                    error = true;

                    warn!("poll error {:?}", e);
                }
            }
        }

        Err(anyhow::anyhow!("Git hash unchanged."))
    }

    fn once(&self) -> Result<Status> {
        let resp = reqwest::blocking::get(&self.url)?.json::<Status>()?;

        info!("{:?}", resp);

        Ok(resp)
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

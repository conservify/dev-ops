use anyhow::Result;
use clap::{Args, Parser, Subcommand};
use serde::Deserialize;
use ssh2::Session;
use std::net::TcpStream;
use std::path::PathBuf;
use std::thread;
use std::{io::prelude::*, path::Path};
use tracing::*;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

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
            "copying {} bytes to {}:{}",
            file_meta.len(),
            &server.ip,
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

struct PrepareStep {
    exec: Executor,
    server: Server,
    archive: PathBuf,
}

impl PrepareStep {
    fn run(&self) -> Result<()> {
        self.exec.execute(&self.server, "whoami")?;
        self.exec.execute(&self.server, "sudo rm -f *.tar")?;
        self.exec.scp(&self.server, &self.archive)?;

        Ok(())
    }
}

struct CommitStep {
    exec: Executor,
    server: Server,
}

impl CommitStep {
    fn run(&self) -> Result<()> {
        self.exec
            .execute(&self.server, "sudo mv *.tar /tmp/incoming-stacks")?;

        Ok(())
    }
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
            let servers = vec![Server {
                id: "NOT USED".to_owned(),
                ip: "192.168.0.110".to_owned(),
                key: "NOT USED".to_owned(),
                ssh_at: "NOT USED".to_owned(),
                user: "jlewallen".to_owned(),
            }];

            let preparations = servers
                .iter()
                .map(|server| PrepareStep {
                    exec: exec.clone(),
                    server: server.clone(),
                    archive: deploy.archive.clone(),
                })
                .collect::<Vec<_>>();

            info!("preparing");

            let tasks = preparations
                .into_iter()
                .map(|step| thread::spawn(move || step.run()))
                .collect::<Vec<_>>();

            let joined = tasks
                .into_iter()
                .map(|j| j.join().map_err(|e| anyhow::anyhow!("{:?}", e)))
                .collect::<Result<Vec<_>>>()?;

            info!("{:?}", joined);

            let commits = servers
                .iter()
                .map(|server| CommitStep {
                    exec: exec.clone(),
                    server: server.clone(),
                })
                .collect::<Vec<_>>();

            info!("committing");

            let tasks = commits
                .into_iter()
                .map(|step| thread::spawn(move || step.run()))
                .collect::<Vec<_>>();

            let joined = tasks
                .into_iter()
                .map(|j| j.join().map_err(|e| anyhow::anyhow!("{:?}", e)))
                .collect::<Result<Vec<_>>>()?;

            info!("{:?}", joined);
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

#[derive(Deserialize, Clone, Debug)]
#[allow(dead_code)]
struct Server {
    id: String,
    ip: String,
    key: String,
    #[serde(rename = "sshAt")]
    ssh_at: String,
    user: String,
}

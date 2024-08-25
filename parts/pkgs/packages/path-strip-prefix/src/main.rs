use clap::Parser;
use std::io;
use std::path::{Path, PathBuf};

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[arg()]
    prefix: PathBuf,
}

fn main() {
    let args = Args::parse();

    for line in io::stdin().lines() {
        match line {
            Ok(line) => {
                let path = Path::new(&line);
                if let Ok(relpath) = path.strip_prefix(&args.prefix) {
                    println!("{}", relpath.display());
                    continue;
                }
                eprintln!(
                    "\"{}\" is not a prefix of \"{}\"",
                    args.prefix.display(),
                    path.display()
                );
                println!("{}", line);
            }
            Err(e) => eprintln!("Failed to read line: {e}"),
        }
    }
}

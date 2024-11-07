use core::Result;
use fs::list_repositories;
use output::get_output_fn;

mod cli;
mod core;
mod fs;
mod marshall;
mod output;

/// Recursively scans [cli::CommandLineArgs::root] looking for Git repositories, and prints all
/// paths to stdout according to the specified [cli::CommandLineArgs::output] format.
/// Looks no further than [cli::CommandLineArgs::max_depth] depth.
/// Note that only [cli::OutputFormat::Machine] is guaranteed to be lossless: based on the host
/// system [std::path::PathBuf::display()] may have to substitute non-unicode characters.
/// On the other hand [cli::OutputFormat::Machine] encodes raw [PathBuf]s, therefore preserving
/// the original encoding.
/// Shell expansion is not performed on [cli::CommandLineArgs::root] and thus must be performed
/// out of band.
fn main() -> Result<()> {
    let args = cli::CommandLineArgs::parse();

    let output = get_output_fn(args.output);
    let matches = list_repositories(&args.root, args.max_depth)?;

    output(matches)
}

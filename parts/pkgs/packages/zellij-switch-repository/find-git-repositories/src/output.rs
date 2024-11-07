use std::io::Write;
use std::{collections::BTreeSet, io::IsTerminal, path::PathBuf};

use super::cli::OutputFormat;
use super::core::{Error, Result};
use super::marshall::serialize;

type OutputFn = fn(BTreeSet<PathBuf>) -> Result<()>;

pub(super) fn get_output_fn(format: OutputFormat) -> OutputFn {
    // TODO: move this out of `main`.
    match format {
        OutputFormat::Auto => {
            if std::io::stdout().is_terminal() {
                output_display
            } else {
                output_machine
            }
        }
        OutputFormat::Display => output_display,
        OutputFormat::Compact => output_compact,
        OutputFormat::Machine => output_machine,
    }
}

/// Prints the paths to the standard output, one per line.
/// This is a human-friendly output format.
fn output_display(paths: BTreeSet<PathBuf>) -> Result<()> {
    for path in paths {
        println!("{}", path.display());
    }

    Ok(())
}

/// Prints the paths to the standard output, separated by `\0`.
/// This is a lossy machine-friendly output format.
fn output_compact(paths: BTreeSet<PathBuf>) -> Result<()> {
    for path in paths {
        print!("{}\0", path.display());
    }

    Ok(())
}

/// Prints the paths to the standard output, serialized into the RMP format.
/// This is a lossless machine-friendly output format.
fn output_machine(paths: BTreeSet<PathBuf>) -> Result<()> {
    let buf = serialize(&paths)?;

    if let Err(error) = std::io::stdout().write_all(&buf.as_ref()) {
        return Err(Error::OutputWriteFailed(error.into()));
    }

    Ok(())
}

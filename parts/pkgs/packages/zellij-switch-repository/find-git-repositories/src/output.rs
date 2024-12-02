use std::io::Write;
use std::{collections::BTreeMap, io::IsTerminal, path::PathBuf};

use super::cli::OutputFormat;
use super::core::{Error, Result};
use super::marshall::serialize;

type OutputFn = fn(BTreeMap<PathBuf, PathBuf>) -> Result<()>;

pub(super) fn get_output_fn(format: OutputFormat) -> OutputFn {
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
fn output_display(paths: BTreeMap<PathBuf, PathBuf>) -> Result<()> {
    for (label, path) in paths {
        println!("{} -> {}", label.display(), path.display());
    }

    Ok(())
}

/// Prints the paths to the standard output, separated by `\0`.
/// This is a lossy machine-friendly output format.
fn output_compact(paths: BTreeMap<PathBuf, PathBuf>) -> Result<()> {
    for (label, path) in paths {
        print!("{}\0{}\0", label.display(), path.display());
    }

    Ok(())
}

/// Prints the paths to the standard output, serialized into the RMP format.
/// This is a lossless machine-friendly output format.
fn output_machine(paths: BTreeMap<PathBuf, PathBuf>) -> Result<()> {
    let buf = serialize(&paths)?;

    if let Err(error) = std::io::stdout().write_all(&buf.as_ref()) {
        return Err(Error::OutputWriteFailed(error.into()));
    }

    Ok(())
}

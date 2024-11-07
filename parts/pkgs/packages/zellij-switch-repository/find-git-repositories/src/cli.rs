use std::path::PathBuf;

use clap::{Parser, ValueEnum};

#[derive(Parser)]
#[command(version, about, long_about = None)]
pub(super) struct CommandLineArgs {
    /// The root directory from where to start the scan.
    #[arg()]
    pub(super) root: PathBuf,

    /// The max depth at which to stop inspecting child directories.
    #[arg(short, long, default_value_t = usize::MAX)]
    pub(super) max_depth: usize,

    /// The format in which to print the results on the standard output.
    #[arg(short, long, value_enum, default_value_t = OutputFormat::Auto)]
    pub(super) output: OutputFormat,
}

#[derive(Copy, Clone, ValueEnum)]
pub(super) enum OutputFormat {
    /// Equivalent to [OutputFormat::Machine] if stdout is not a TTY, else [OutputFormat::Display].
    Auto,

    /// Prints the full file name on the standard output, followed by a newline character.
    /// This output mode is potentially lossy if the path contains non-unicode characters.
    Display,

    /// Prints the full file name on the standard output, followed by a null character. This allows
    /// file names that contain newlines or other types of white space to be correctly interpreted
    /// by programs that process the find output.
    /// This option corresponds to the -0 option of xargs.
    /// This output mode is potentially lossy if the path contains non-unicode characters.
    Compact,

    /// Prints the serialized list of [PathBuf] on the standard output.
    /// This option is useful for deserializing the output from another rust program.
    Machine,
}

impl CommandLineArgs {
    pub(super) fn parse() -> Self {
        <Self as Parser>::parse()
    }
}

#[test]
fn verify_cli() {
    use clap::CommandFactory;
    CommandLineArgs::command().debug_assert();
}

/// Declaration of the common types used across this crate's implementation.
use anyhow;
use thiserror;

/// These errors indicate an issue with the program. They are not recoverable.
#[derive(thiserror::Error, Debug)]
pub(super) enum Error {
    #[error("An unexpected error happened. Check the logs for more information.")]
    UnexpectedError(#[from] anyhow::Error),
    #[error("Failed to read filesystem: {0:?}")]
    FileSystemReadFailed(anyhow::Error),
    #[error("Failed to serialize or write to output stream: {0:?}")]
    OutputWriteFailed(anyhow::Error),
}

/// The common result type used in this program.
pub(super) type Result<T> = anyhow::Result<T, Error>;

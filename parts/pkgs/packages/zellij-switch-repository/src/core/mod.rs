/// Declaration of the common types used across this plugin's implementation.
use anyhow;
use thiserror;

mod render_strategy;
mod result_iter;

/// These errors indicate either user error (e.g. configuration), or issues with the Zellij API.
/// They should not crash the plugin and be reported to the user. They may or may not be
/// recoverable.
/// These are meant to be logged against the [crate::context::Context] to be reported to the user
/// via the UI.
#[derive(thiserror::Error, Debug)]
pub(crate) enum PluginError {
    #[error("An unexpected error happened and the SwitchRepository plugin may no longer be stable. Check the logs for more information.")]
    UnexpectedError(#[from] anyhow::Error),
    #[error("Failed to scan filesystem: {0:?}")]
    FileSystemScanFailed(anyhow::Error),
    #[error("Invalid configuration: {reason}")]
    ConfigurationError { reason: String },
    #[error("Unknown pipe message `{0}`")]
    UnknownPipeMessageError(String),
    #[error("Missing pipe message payload for `{0}`")]
    MissingPipeMessagePayloadError(String),
    #[error("Invalid pipe message payload: `{0}`")]
    InvalidPipeMessagePayloadError(String),
    #[error("Failed to switch to session {session_name:?}: {reason}")]
    SwitchSessionFailed {
        session_name: String,
        reason: &'static str,
    },
}

/// Whether the plugin should refresh its UI.
///
/// If [PluginUpdateLoop::MarkDirty], then the plugin will notify Zellij that it needs to rerender
/// itself, which will trigger a call to `SwitchRepositoryPlugin::render(…)`.
// TODO: Consider adding `ShowPane`, `ClearPane`, `ClosePane` and `Terminate`.
#[derive(Copy, Clone)]
pub(crate) enum PluginUpdateLoop {
    MarkDirty,
    NoUpdates,
}

/// The result of an event loop cycle. Contains either a rendering strategy that dictacts whether
/// the UI should redraw itself and therefore request a redraw to the Zellij engine, or an error
/// that should be displayed to the user (which always implies a UI redraw).
pub(crate) type Result = anyhow::Result<PluginUpdateLoop, InternalError>;

/// These errors report invalid internal state. They indicate an issue with the plugin's
/// implementation and should probably be fatal.
/// These are meant to be reported via this crate's [Result] type.
#[derive(thiserror::Error, Debug)]
pub(crate) enum InternalError {
    #[error("unexpected plugin error: {0:?}")]
    Unknown(#[from] anyhow::Error),
    #[error("unexpected selected index: {0}")]
    SelectionIndexOutOfBounds(usize),
}

/// A trait for utility functions on iterators of [Result].
pub(crate) trait ResultIterator: Iterator {
    /// An iterator method that reduces [Result]s as long as they represent a successful value,
    /// producing a single, final value.
    ///
    /// The reducing closure either returns successfully, with the value that the accumulator
    /// should have for the next iteration, or it returns failure, with an error value that is
    /// propagated back to the caller immediately (short-circuiting).
    ///
    /// If the iterator is empty, returns `Ok(Default::default())`.
    fn try_consume(self: &mut Self) -> Result
    where
        Self: Sized;
}

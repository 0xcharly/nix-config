use crate::ui;
/// Declaration of the common types used across this plugin's implementation.
use anyhow;
use thiserror;

/// The result of an event loop cycle. Contains either a rendering strategy that dictacts whether
/// the UI should redraw itself and therefore request a redraw to the Zellij engine, or an error
/// that should be displayed to the user (which always implies a UI redraw).
pub(crate) type Result = anyhow::Result<ui::RenderStrategy>;

#[derive(thiserror::Error, Debug)]
pub(crate) enum PluginError {
    #[error("unexpected plugin error: {0:?}")]
    Unknown(#[from] anyhow::Error),
    #[error("invalid configuration: {reason}")]
    ConfigurationError { reason: &'static str },
    #[error("failed to switch to session {session_name:?}: {reason}")]
    SwitchSessionFailed {
        session_name: String,
        reason: &'static str,
    },
}

#[derive(thiserror::Error, Debug)]
pub(crate) enum InternalError {
    #[error("unexpected plugin error: {0:?}")]
    Unknown(#[from] anyhow::Error),
    #[error("unexpected selected index: {0}")]
    InvalidIndex(usize),
}

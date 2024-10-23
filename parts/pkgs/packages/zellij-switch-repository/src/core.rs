use std::iter::Map;

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

/// A trait for utility functions on `Result`.
pub(crate) trait ResultOps {
    fn combine(self, rhs: Self) -> Self;
}

impl ResultOps for Result {
    /// Combine two [Result]s.
    ///
    /// Arguments passed to `combine` are eagerly evaluated.
    fn combine(self, rhs: Self) -> Self {
        match (self, rhs) {
            (Ok(a), Ok(b)) => Ok(a | b),
            // TODO: report errors to the UIs.
            _ => Ok(ui::RenderStrategy::DrawNextFrame),
        }
    }
}

/// A trait for utility functions on `Result`'s iterators.
pub(crate) trait ResultIteratorOps: Iterator {
    /// Reduces the [Result]s to a single one, by repeatedly folding them into each other.
    ///
    /// If the iterator is empty, returns `Ok(ui::RenderStrategy::SkipNextFrame)`, otherwise
    /// returns the result of the reduction.
    fn conflate_results(self: Self) -> Result
    where
        Self: Sized;
}

impl<I: Iterator, F> ResultIteratorOps for Map<I, F>
where
    F: FnMut(I::Item) -> Result,
{
    fn conflate_results(self: Self) -> Result {
        // NOTE: Consumes all elements to avoid skipping events.
        self.reduce(|a, b| a.combine(b))
            .unwrap_or(Ok(ui::RenderStrategy::SkipNextFrame))
    }
}

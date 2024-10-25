/// Declaration of the common types used across this plugin's implementation.
use crate::ui;

use anyhow;
use std::iter::Map;
use thiserror;

/// The result of an event loop cycle. Contains either a rendering strategy that dictacts whether
/// the UI should redraw itself and therefore request a redraw to the Zellij engine, or an error
/// that should be displayed to the user (which always implies a UI redraw).
pub(crate) type Result = anyhow::Result<ui::RenderStrategy>;

// TODO: these errors should be reported back to the UI.
/// These errors indicate either user error (e.g. configuration), or issues with the Zellij API.
/// They should be recoverable and reported to the user.
#[derive(thiserror::Error, Debug)]
pub(crate) enum PluginError {
    #[error("invalid configuration: {reason}")]
    ConfigurationError { reason: &'static str },
    #[error("failed to switch to session {session_name:?}: {reason}")]
    SwitchSessionFailed {
        session_name: String,
        reason: &'static str,
    },
}

/// These errors report invalid internal state. They indicate an issue with the plugin's
/// implementation and should probably be fatal.
#[derive(thiserror::Error, Debug)]
pub(crate) enum InternalError {
    #[error("unexpected plugin error: {0:?}")]
    Unknown(#[from] anyhow::Error),
    #[error("unexpected selected index: {0}")]
    SelectionIndexOutOfBounds(usize),
}

/// A trait for utility functions on iterators of [Result].
pub(crate) trait ResultIteratorOps: Iterator {
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

impl<I: Iterator, F> ResultIteratorOps for Map<I, F>
where
    F: FnMut(I::Item) -> Result,
{
    fn try_consume(self: &mut Self) -> Result {
        self.try_fold(Default::default(), std::ops::BitOr::bitor)
    }
}

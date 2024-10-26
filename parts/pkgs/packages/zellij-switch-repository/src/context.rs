use crate::core::{PluginError, PluginUpdateLoop};

/// The plugin context holds volatile state such as non-fatal errors that should be reported to the
/// user via the UI.
#[derive(Default)]
pub(crate) struct Context {
    /// Non-fatal errors raised during plugin execution. While non-fatal, some errors may not be
    /// recoverable.
    errors: Vec<PluginError>,
}

impl Context {
    pub(crate) fn log_error(&mut self, error: PluginError) -> PluginUpdateLoop {
        self.errors.push(error);
        PluginUpdateLoop::MarkDirty
    }

    pub(crate) fn clear_errors(&mut self) -> PluginUpdateLoop {
        self.errors.clear();
        PluginUpdateLoop::MarkDirty
    }

    pub(crate) fn errors(&self) -> &Vec<PluginError> {
        &self.errors
    }
}

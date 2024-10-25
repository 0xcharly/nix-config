use crate::core;
use crate::ui::RenderStrategy;

/// The plugin context holds volatile state such as non-fatal errors that should be reported to the
/// user via the UI.
#[derive(Default)]
pub(crate) struct Context {
    /// Non-fatal errors raised during plugin execution. While non-fatal, some errors may not be
    /// recoverable.
    errors: Vec<core::PluginError>,
}

impl Context {
    pub(crate) fn log_error(&mut self, error: core::PluginError) -> RenderStrategy {
        self.errors.push(error);
        RenderStrategy::DrawNextFrame
    }

    pub(crate) fn clear_errors(&mut self) -> RenderStrategy {
        self.errors.clear();
        RenderStrategy::DrawNextFrame
    }

    pub(crate) fn errors(&self) -> &Vec<core::PluginError> {
        &self.errors
    }
}

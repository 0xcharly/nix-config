use crate::context::Context;
use crate::matcher::Match;

use styles::Styles;

mod frame;
mod renderer;
mod styles;

pub const PANE_TITLE: &'static str = "Select a directory:";

#[derive(Default)]
pub(crate) struct Renderer {
    styles: Styles,
}

/// Represents a plugin UI frame of size [rows]×[cols].
///
/// Implements the [std::fmt::Display] trait to easily render it via Zellij's API.
pub(crate) struct Frame<'ui> {
    rows: usize,
    cols: usize,
    context: &'ui Context,
    styles: &'ui Styles,

    user_input: &'ui str,
    matched_results: &'ui Vec<Match>,
    selection_index: usize,
    total_result_count: usize,
}

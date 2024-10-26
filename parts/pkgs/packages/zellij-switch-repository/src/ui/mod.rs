use crate::context::Context;
use crate::matcher::Match;

use styles::Styles;

mod frame;
mod renderer;
mod styles;

pub const PANE_TITLE: &'static str = "Select a repository:";

#[derive(Default)]
pub(crate) struct Renderer {
    styles: Styles,
    selected_index: usize,

    // TODO: Add support for tracking the selected match: i.e. instead of only tracking the
    // selected index, also track the selected match in case it appears in successive results.
    //
    // For example, given the current set of results and selection cursor:
    //
    // ```
    //     nix-config
    //     nix-config-ghostty
    //   > nix-config-nvim
    //     nix-config-manager
    // ```
    //
    // And assuming the next user input changes the results to:
    //
    // ```
    //     nix-config-ghostty
    //   > nix-config-nvim
    //     nix-config-manager
    // ```
    //
    // Keeping track of the selected match would allow us to move the cursor to the second entry
    // (the one the user manually selected already) instead of leaving it on the third one.
    #[allow(dead_code)]
    selected_match: Option<Match>,
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

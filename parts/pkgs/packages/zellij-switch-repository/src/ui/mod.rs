use crate::core::Result;
use crate::matcher::Match;

use ansi_term::Style;
use std::ops::{BitAnd, BitOr};

mod frame;
mod renderer;
mod styles;

pub const PANE_TITLE: &'static str = "Select a repository:";

/// Whether the plugin should refresh its UI.
///
/// If [RenderStrategy::DrawNextFrame], then the plugin will notify Zellij that it needs to
/// rerender itself, which will trigger a call to `SwitchRepositoryPlugin::render(…)`.
#[derive(Copy, Clone)]
pub(crate) enum RenderStrategy {
    DrawNextFrame,
    SkipNextFrame,
}

impl Default for RenderStrategy {
    fn default() -> Self {
        RenderStrategy::SkipNextFrame
    }
}

impl RenderStrategy {
    pub fn as_bool(&self) -> bool {
        match self {
            RenderStrategy::DrawNextFrame => true,
            RenderStrategy::SkipNextFrame => false,
        }
    }

    /// Short-circuiting `&&` operator for [RenderStrategy].
    pub fn and_then<F>(&self, then_fn: F) -> Self
    where
        F: FnOnce() -> Self,
    {
        if self.as_bool() {
            then_fn()
        } else {
            *self
        }
    }

    /// Short-circuiting `||` operator for [RenderStrategy].
    pub fn or_else<F>(&self, else_fn: F) -> Self
    where
        F: FnOnce() -> Self,
    {
        if self.as_bool() {
            *self
        } else {
            else_fn()
        }
    }
}

impl From<bool> for RenderStrategy {
    fn from(value: bool) -> Self {
        match value {
            true => Self::DrawNextFrame,
            false => Self::SkipNextFrame,
        }
    }
}

impl BitAnd for RenderStrategy {
    type Output = RenderStrategy;

    fn bitand(self, rhs: Self) -> Self::Output {
        (self.as_bool() & rhs.as_bool()).into()
    }
}

impl BitOr for RenderStrategy {
    type Output = RenderStrategy;

    fn bitor(self, rhs: Self) -> Self::Output {
        (self.as_bool() | rhs.as_bool()).into()
    }
}

impl BitOr<Result> for RenderStrategy {
    type Output = Result;

    fn bitor(self, rhs: Result) -> Self::Output {
        match rhs {
            Ok(value) => Ok(self | value),
            err => err,
        }
    }
}

pub(crate) struct Styles {
    pub none: Style,
    pub caret: Style,
    pub cursor: Style,
    pub prompt: Style,
    pub separator: Style,
    pub matched: Style,
    pub selected: Style,
    pub selected_and_matched: Style,
}

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
    styles: &'ui Styles,

    user_input: &'ui str,
    matched_results: &'ui Vec<Match>,
    selection_index: usize,
    total_result_count: usize,
}

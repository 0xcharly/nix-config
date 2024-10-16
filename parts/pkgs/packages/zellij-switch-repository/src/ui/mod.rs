use std::ops::{BitAnd, BitOr};

use ansi_term::Style;

use crate::matcher::Match;

mod frame;
mod renderer;
mod styles;

// TODO: figure out a better name.
// TODO: consider adding a new `Force` option (which could be used to avoid special cases such as
// in `RepositoryMatcher::apply(…)`)
/// Whether the plugin should refresh its UI.
/// If `Rerender::Yes`, then the plugin will notify Zellij that it needs to rerender itself, which
/// will trigger a call to `State::render(…)`.
#[derive(Copy, Clone)]
pub(crate) enum Rerender {
    Yes,
    No,
}

impl Rerender {
    pub fn as_bool(&self) -> bool {
        match self {
            Rerender::Yes => true,
            Rerender::No => false,
        }
    }

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

impl From<bool> for Rerender {
    fn from(value: bool) -> Self {
        match value {
            true => Rerender::Yes,
            false => Rerender::No,
        }
    }
}

impl BitAnd for Rerender {
    type Output = Rerender;

    fn bitand(self, rhs: Self) -> Self::Output {
        match (self, rhs) {
            (Rerender::Yes, Rerender::Yes) => Rerender::Yes,
            (Rerender::Yes, Rerender::No) => Rerender::No,
            (Rerender::No, Rerender::Yes) => Rerender::No,
            (Rerender::No, Rerender::No) => Rerender::No,
        }
    }
}

impl BitOr for Rerender {
    type Output = Rerender;

    fn bitor(self, rhs: Self) -> Self::Output {
        match (self, rhs) {
            (Rerender::Yes, Rerender::Yes) => Rerender::Yes,
            (Rerender::Yes, Rerender::No) => Rerender::Yes,
            (Rerender::No, Rerender::Yes) => Rerender::Yes,
            (Rerender::No, Rerender::No) => Rerender::No,
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

pub(crate) struct Frame<'ui> {
    rows: usize,
    cols: usize,
    styles: &'ui Styles,

    user_input: &'ui str,
    matched_results: &'ui Vec<Match>,
    selection_index: usize,
    total_result_count: usize,
}

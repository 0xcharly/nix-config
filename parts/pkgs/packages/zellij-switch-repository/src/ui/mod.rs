use std::ops::{BitAnd, BitOr};

use ansi_term::Style;

use crate::matcher::Match;

mod frame;
mod renderer;
mod styles;

// TODO: figure out a better name.
#[derive(Copy, Clone)]
pub enum Rerender {
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

pub struct Styles {
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
pub struct Renderer {
    styles: Styles,
    selected_index: usize,
    selected_match: Option<Match>,
}

pub struct Frame<'ui> {
    rows: usize,
    cols: usize,
    styles: &'ui Styles,

    user_input: &'ui str,
    matched_results: &'ui Vec<Match>,
    selection_index: usize,
    total_result_count: usize,
}

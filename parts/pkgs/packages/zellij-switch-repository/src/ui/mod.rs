mod frame;
mod renderer;
mod styles;

use ansi_term::Style;

use crate::model::Match;

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

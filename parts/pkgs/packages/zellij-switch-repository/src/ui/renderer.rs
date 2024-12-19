use super::{Frame, Renderer};
use crate::context::Context;

impl Renderer {
    pub fn next_frame<'ui>(
        &'ui self,
        rows: usize,
        cols: usize,
        context: &'ui Context,
    ) -> Frame<'ui> {
        Frame {
            rows,
            cols,
            context,
            styles: &self.styles,
            user_input: &context.user_input(),
            matched_results: &context.matches(),
            selection_index: context.selected_index(),
            total_result_count: context.choice_count(),
        }
    }
}

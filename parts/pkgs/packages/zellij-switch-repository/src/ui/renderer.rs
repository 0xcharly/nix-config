use super::{Frame, Renderer};
use crate::context::Context;
use crate::core::Result;
use crate::matcher::RepositoryMatcher;

impl Renderer {
    pub fn next_frame<'ui>(
        &'ui self,
        rows: usize,
        cols: usize,
        context: &'ui Context,
        matcher: &'ui RepositoryMatcher,
    ) -> Frame<'ui> {
        Frame {
            rows,
            cols,
            context,
            styles: &self.styles,
            user_input: &matcher.user_input(),
            matched_results: &matcher.matches,
            selection_index: self.selected_index,
            total_result_count: matcher.choice_count(),
        }
    }

    pub fn on_user_input(&mut self, matcher: &RepositoryMatcher) -> Result {
        let previous_index = self.selected_index;
        self.selected_index = self
            .selected_index
            .clamp(0, matcher.matches.len().saturating_sub(1));
        Ok((previous_index != self.selected_index).into())
    }

    pub fn select_up(&mut self, matcher: &RepositoryMatcher) -> Result {
        let previous_index = self.selected_index;
        self.selected_index = self
            .selected_index
            .saturating_sub(1)
            .clamp(0, matcher.matches.len().saturating_sub(1));
        Ok((previous_index != self.selected_index).into())
    }

    pub fn select_down(&mut self, matcher: &RepositoryMatcher) -> Result {
        let previous_index = self.selected_index;
        self.selected_index = self
            .selected_index
            .saturating_add(1)
            .clamp(0, matcher.matches.len().saturating_sub(1));
        Ok((previous_index != self.selected_index).into())
    }

    // TODO: improve that, and add support for remembering the selection if still available after
    // user input.
    pub fn get_selected_index(&self) -> usize {
        self.selected_index
    }
}

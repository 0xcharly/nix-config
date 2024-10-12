use crate::matcher::RepositoryMatcher;

use super::{Frame, Renderer};

impl Renderer {
    pub fn next_frame<'ui>(
        &'ui self,
        rows: usize,
        cols: usize,
        matcher: &'ui RepositoryMatcher,
    ) -> Frame<'ui> {
        Frame {
            rows,
            cols,
            styles: &self.styles,
            user_input: &matcher.user_input(),
            matched_results: &matcher.matches,
            selection_index: self.selected_index,
            total_result_count: matcher.choice_count(),
        }
    }

    pub fn on_user_input(&mut self, matcher: &RepositoryMatcher) -> bool {
        let previous_index = self.selected_index;
        self.selected_index = self.selected_index.clamp(0, matcher.matches.len() - 1);
        previous_index != self.selected_index
    }

    pub fn select_up(&mut self, matcher: &RepositoryMatcher) -> bool {
        let previous_index = self.selected_index;
        self.selected_index = self
            .selected_index
            .saturating_sub(1)
            .clamp(0, matcher.matches.len() - 1);
        previous_index != self.selected_index
    }

    pub fn select_down(&mut self, matcher: &RepositoryMatcher) -> bool {
        let previous_index = self.selected_index;
        self.selected_index = self
            .selected_index
            .saturating_add(1)
            .clamp(0, matcher.matches.len() - 1);
        previous_index != self.selected_index
    }

    // TODO: improve that, and add support for remembering the selection if still available after
    // user input.
    pub fn get_selected_index(&self) -> usize {
        self.selected_index
    }
}

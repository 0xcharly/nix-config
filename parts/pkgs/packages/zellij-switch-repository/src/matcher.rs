use std::collections::BTreeSet;

use fuzzy_matcher::skim::SkimMatcherV2;
use fuzzy_matcher::FuzzyMatcher;

pub trait Choice {
    fn repr<'c>(&'c self) -> &'c str;
}

pub(crate) struct Match<'c, C: Choice> {
    pub indices: Vec<usize>,
    pub choice: &'c C,
}

pub(crate) struct RepositoryMatcher {
    matcher: SkimMatcherV2,
}

impl Default for RepositoryMatcher {
    fn default() -> Self {
        Self {
            matcher: SkimMatcherV2::default().use_cache(true),
        }
    }
}

impl RepositoryMatcher {
    //pub fn remove_trailing_char(&mut self) -> PluginUpdateLoop {
    //    PluginUpdateLoop::from(self.user_input.pop().is_some())
    //        .and_then(|| self.apply() | PluginUpdateLoop::MarkDirty)
    //}
    //
    //pub fn on_user_input(&mut self, ch: char) -> PluginUpdateLoop {
    //    self.user_input.push(ch);
    //    // Force update since the user input changed (even if the list of results may not have as a
    //    // result).
    //    self.apply() | PluginUpdateLoop::MarkDirty
    //}
    //
    //pub fn clear_user_input(&mut self) -> PluginUpdateLoop {
    //    let is_empty = self.user_input().is_empty();
    //    self.user_input.clear();
    //    self.apply() | PluginUpdateLoop::from(!is_empty)
    //}

    fn apply<'c, C: Choice>(&self, input: &str, choices: &'c BTreeSet<C>) -> Vec<Match<'c, C>> {
        choices
            .iter()
            .filter_map(|choice| {
                self.matcher
                    .fuzzy_indices(choice.repr(), input)
                    .map(|(_score, indices)| Match { indices, choice })
            })
            .collect()
    }
}

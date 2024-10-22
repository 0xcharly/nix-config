use std::collections::BTreeSet;
use std::path::PathBuf;

use fuzzy_matcher::skim::SkimMatcherV2;
use fuzzy_matcher::FuzzyMatcher;

use crate::plugin::Result;
use crate::ui::RenderStrategy;

#[derive(PartialEq)]
pub(crate) struct Match {
    pub indices: Vec<usize>,
    pub entry: String,
}

pub(crate) struct RepositoryMatcher {
    pub matches: Vec<Match>,

    choices: BTreeSet<PathBuf>,
    matcher: SkimMatcherV2,
    user_input: String,
}

impl Default for RepositoryMatcher {
    fn default() -> Self {
        Self {
            matches: Vec::new(),
            choices: BTreeSet::new(),
            matcher: SkimMatcherV2::default().use_cache(true),
            user_input: String::new(),
        }
    }
}

impl RepositoryMatcher {
    pub fn add_choice(&mut self, choice: PathBuf) {
        self.choices.insert(choice);
        self.apply(/* force_render */ false);
    }

    pub fn remove_trailing_char(&mut self) -> Result {
        Ok(RenderStrategy::from(self.user_input.pop().is_some())
            .and_then(|| self.apply(/* force_render */ true)))
    }

    pub fn on_user_input(&mut self, ch: char) -> Result {
        self.user_input.push(ch);
        Ok(self.apply(/* force_render */ true))
    }

    pub fn clear_user_input(&mut self) -> Result {
        let is_empty = self.user_input().is_empty();
        self.user_input.clear();
        Ok(self.apply(/* force_render */ !is_empty))
    }

    pub fn choice_count(&self) -> usize {
        self.choices.len()
    }

    pub fn user_input(&self) -> &str {
        &self.user_input
    }

    fn apply(&mut self, force_render: bool) -> RenderStrategy {
        let previous_matches = std::mem::take(&mut self.matches);

        for choice in self.choices.iter().filter_map(|p| p.to_str()) {
            if let Some((_score, indices)) = self
                .matcher
                .fuzzy_indices(choice, &self.user_input.as_str())
            {
                self.matches.push(Match {
                    indices,
                    entry: choice.to_owned(),
                });
            }
        }

        let render = force_render
            || self.matches.len() != previous_matches.len()
            || self
                .matches
                .iter()
                .zip(&previous_matches)
                .any(|(a, b)| a != b);

        render.into()
    }
}

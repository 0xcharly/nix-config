use super::Frame;
use std::fmt::{Display, Formatter, Result};

const SEARCH_PREFIX: &'static str = ">";

impl<'ui> Frame<'ui> {
    fn fmt_stats(&self, f: &mut Formatter<'_>) -> Result {
        let stats = format!(
            "  {}/{}",
            self.matched_results.len(),
            self.total_result_count
        );
        let fills = "─".repeat(self.cols.saturating_sub(stats.len() + 3));
        writeln!(
            f,
            "{} {}",
            self.styles.separator.paint(stats),
            self.styles.separator.paint(fills)
        )?;

        Ok(())
    }
}

impl Display for Frame<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result {
        // User input line.
        writeln!(
            f,
            "{} {}{}",
            self.styles.prompt.paint(SEARCH_PREFIX),
            self.user_input,
            self.styles.cursor.paint(" ")
        )?;

        // Filtered results.
        self.fmt_stats(f)?;
        let mut ch_buf = [0; 2];
        for (index, m) in self
            .matched_results
            .iter()
            .take(self.rows.saturating_sub(2))
            .enumerate()
        {
            let is_selected = index == self.selection_index;
            let styled_entry = m
                .entry
                .char_indices()
                .map(|(idx, ch)| {
                    let style = match (m.indices.contains(&idx), is_selected) {
                        (true, true) => self.styles.selected_and_matched,
                        (false, true) => self.styles.selected,
                        (true, false) => self.styles.matched,
                        _ => self.styles.none,
                    };
                    style.paint(ch.encode_utf8(&mut ch_buf) as &str).to_string()
                })
                .collect::<String>();
            if index == self.selection_index {
                let fills = " ".repeat(self.cols.saturating_sub(2 + m.entry.len()));
                writeln!(
                    f,
                    "{}{styled_entry}{}",
                    self.styles.caret.paint("> "),
                    self.styles.selected.paint(&fills)
                )?;
            } else {
                writeln!(f, "  {styled_entry}")?;
            }
        }

        Ok(())
    }
}

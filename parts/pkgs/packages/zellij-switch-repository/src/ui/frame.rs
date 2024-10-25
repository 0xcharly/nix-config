use super::Frame;
use std::fmt::{Display, Formatter, Result};

const SEARCH_PREFIX: &'static str = ">";

/// Takes into account the following constantly visble lines:
///   - At the top, the first 2 lines:
///     - User input
///     - Separator
///   - At the bottom, the last 2 lines:
///     - Tips
///     - Status line
const CHROME_LINE_COUNT: usize = 4;

// TODO: deal with lack of horizontal space (truncate and/or ellipsize).

impl<'ui> Frame<'ui> {
    fn fmt_user_input(&self, f: &mut Formatter<'_>) -> Result {
        writeln!(
            f,
            "{} {}{}",
            self.styles.prompt.paint(SEARCH_PREFIX),
            self.user_input,
            self.styles.cursor.paint(" ")
        )
    }

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
        )
    }

    fn fmt_tips(&self, f: &mut Formatter<'_>) -> Result {
        writeln!(
            f,
            "<{}> {} / <{}> {} / <{}> {}",
            self.styles.keycode.paint("↓↑"),
            self.styles.label.paint("Navigate between entries"),
            self.styles.keycode.paint("ENTER"),
            self.styles.label.paint("Select entry"),
            self.styles.keycode.paint("ESC"),
            self.styles.label.paint("Clear input"),
        )
    }

    /// Prints errors, if any.
    /// Since this is the last line, skip the final newline.
    fn fmt_errors(&self, f: &mut Formatter<'_>) -> Result {
        let Some(first_error) = self.context.errors().first() else {
            return Ok(());
        };

        write!(f, "{}: ", self.styles.error.paint("Error"))?;

        if self.context.errors().len() == 1 {
            write!(f, "{first_error}")
        } else {
            write!(
                f,
                "{first_error}, and {} others",
                self.context.errors().len() - 1
            )
        }
    }
}

impl Display for Frame<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result {
        // Bail immediately if we don't have the space to render the bare minimum UI.
        if self.rows < CHROME_LINE_COUNT + 1 {
            writeln!(f, "{}", self.styles.error.paint("Plugin pane is too small"))?;
            return Ok(());
        }

        // Header.
        self.fmt_user_input(f)?;
        self.fmt_stats(f)?;

        // Body.
        let mut ch_buf = [0; 2];
        for (index, m) in self
            .matched_results
            .iter()
            .take(self.rows.saturating_sub(4))
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

        // Spacer.
        for _ in 0..self
            .rows
            .saturating_sub(self.matched_results.len() + CHROME_LINE_COUNT + 1)
        {
            writeln!(f)?;
        }

        // Footer.
        self.fmt_tips(f)?;
        self.fmt_errors(f)?;

        Ok(())
    }
}

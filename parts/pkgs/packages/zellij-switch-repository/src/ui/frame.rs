use super::{
    styles::{ControlBar, ControlSegment},
    Frame,
};
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

const CONTROL_BAR: ControlBar = ControlBar {
    segments: [
        ControlSegment {
            control: "↓↑",
            label: "Navigate between entries",
        },
        ControlSegment {
            control: "ENTER",
            label: "Select entry",
        },
        ControlSegment {
            control: "ESC",
            label: "Clear input",
        },
    ],
};

// TODO: deal with narrow panes / reduced horizontal space (truncate and/or ellipsize).

impl<'ui> Frame<'ui> {
    fn fmt_pane_too_small(&self, f: &mut Formatter<'_>) -> Result {
        self.styles.fmt_pane_too_small(f)
    }

    fn fmt_user_input(&self, f: &mut Formatter<'_>) -> Result {
        self.styles
            .fmt_user_input(f, &SEARCH_PREFIX, &self.user_input)
    }

    fn fmt_user_input_divider(&self, f: &mut Formatter<'_>) -> Result {
        self.styles.fmt_user_input_divider(
            f,
            self.matched_results.len(),
            self.total_result_count,
            self.cols,
        )
    }

    fn fmt_matched_results(&self, f: &mut Formatter<'_>) -> Result {
        self.styles.fmt_matched_results(
            f,
            &self.matched_results,
            self.selection_index,
            self.rows.saturating_sub(CHROME_LINE_COUNT),
        )
    }

    fn fmt_spacer(&self, f: &mut Formatter<'_>) -> Result {
        for _ in 0..self
            .rows
            .saturating_sub(self.matched_results.len() + CHROME_LINE_COUNT)
        {
            writeln!(f)?;
        }

        Ok(())
    }

    fn fmt_control_bar(&self, f: &mut Formatter<'_>) -> Result {
        self.styles.fmt_control_bar(f, &CONTROL_BAR)
    }

    /// Prints errors, if any.
    /// Since this is the last line, skip the final newline.
    fn fmt_status_bar(&self, f: &mut Formatter<'_>) -> Result {
        self.styles.fmt_status_bar(f, &self.context)
    }
}

impl Display for Frame<'_> {
    fn fmt(&self, f: &mut Formatter<'_>) -> Result {
        // Bail immediately if we don't have the space to render the bare minimum UI, which
        // consists of the chrome and at least 1 row of results.
        if self.rows < CHROME_LINE_COUNT + 1 {
            return self.fmt_pane_too_small(f);
        }

        // Header.
        self.fmt_user_input(f)?;
        self.fmt_user_input_divider(f)?;

        // Body.
        self.fmt_matched_results(f)?;

        // Spacer: if there's less results than available lines for display, fill up the pane with
        // padding down to the footer.
        self.fmt_spacer(f)?;

        // Footer.
        self.fmt_control_bar(f)?;
        self.fmt_status_bar(f)?;

        Ok(())
    }
}

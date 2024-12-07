#![allow(dead_code)]
// TODO: use std::iter::Itersperse when available.
// https://doc.rust-lang.org/std/iter/struct.Intersperse.html
#![allow(unstable_name_collisions)]

use crate::{context::Context, matcher::Match};
use std::fmt::{Formatter, Result};

use ansi_term::{
    ANSIString, ANSIStrings,
    Colour::{self, Fixed, RGB},
    Style,
};
use itertools::Itertools;

pub(crate) struct Styles {
    none: Style,
    caret: Style,
    cursor: Style,
    prompt: Style,
    error: Style,
    warning: Style,
    separator: Style,
    matched: Style,
    selected: Style,
    selected_and_matched: Style,
    ellipsized: Style,
    selected_and_ellipsized: Style,

    control_background: Style,
    control_keycode: Style,
    control_label: Style,
}

pub(crate) struct ControlSegment<'cs> {
    pub(crate) control: &'cs str,
    pub(crate) short_label: &'cs str,
    pub(crate) full_label: &'cs str,
}

pub(crate) struct ControlBar<'cb> {
    pub(crate) segments: [ControlSegment<'cb>; 3],
}

impl ControlBar<'_> {
    const SEGMENT_SEPARATOR: &'static str = " / ";

    fn full_label_len(&self) -> usize {
        self.segments
            .iter()
            .map(|segment| segment.control.chars().count() + segment.full_label.chars().count() + 3)
            .intersperse(ControlBar::SEGMENT_SEPARATOR.len())
            .sum()
    }

    fn short_label_len(&self) -> usize {
        self.segments
            .iter()
            .map(|segment| {
                segment.control.chars().count() + segment.short_label.chars().count() + 3
            })
            .intersperse(ControlBar::SEGMENT_SEPARATOR.len())
            .sum()
    }

    fn render_separator(styles: &Styles) -> ANSIString<'_> {
        styles
            .control_background
            .paint(ControlBar::SEGMENT_SEPARATOR)
    }

    fn render_full<'s>(&'s self, styles: &'s Styles) -> Vec<ANSIString<'s>> {
        let segment_separators = vec![ControlBar::render_separator(styles)];

        self.segments
            .iter()
            .map(|segment| {
                vec![
                    styles.control_background.paint("<"),
                    styles.control_keycode.paint(segment.control),
                    styles.control_background.paint("> "),
                    styles.control_label.paint(segment.full_label),
                ]
            })
            .intersperse(segment_separators)
            .flatten()
            .collect()
    }

    fn render_short<'s>(&'s self, styles: &'s Styles) -> Vec<ANSIString<'s>> {
        let segment_separators = vec![ControlBar::render_separator(styles)];

        self.segments
            .iter()
            .map(|segment| {
                vec![
                    styles.control_background.paint("<"),
                    styles.control_keycode.paint(segment.control),
                    styles.control_background.paint("> "),
                    styles.control_label.paint(segment.short_label),
                ]
            })
            .intersperse(segment_separators)
            .flatten()
            .collect()
    }

    fn render<'s>(&'s self, styles: &'s Styles, cols: usize) -> Option<Vec<ANSIString<'s>>> {
        match cols {
            _ if self.full_label_len() <= cols => Some(self.render_full(styles)),
            _ if self.short_label_len() <= cols => Some(self.render_short(styles)),
            _ => None,
        }
    }
}

const GREY: u8 = 0;
const RED: u8 = 1;
const GREEN: u8 = 2;
const YELLOW: u8 = 3;
const BLUE: u8 = 4;
const MAGENTA: u8 = 5;
const CYAN: u8 = 6;
const WHITE: u8 = 7;

/// The catppuccin "colorscheme" background.
const CATPPUCCIN_SURFACE_0: Colour = RGB(49, 50, 68);
const GUNMETAL_BACKGROUND: Colour = RGB(29, 31, 33);

impl Default for Styles {
    fn default() -> Self {
        Self {
            none: Style::new(),
            caret: Style::new().fg(Fixed(MAGENTA)).bold(),
            cursor: Style::new().on(Fixed(WHITE)),
            prompt: Style::new().fg(Fixed(MAGENTA)).bold(),
            error: Style::new().fg(Fixed(RED)).bold(),
            warning: Style::new().fg(Fixed(YELLOW)).bold(),
            separator: Style::new().fg(Fixed(CYAN)),
            matched: Style::new().fg(Fixed(MAGENTA)).underline(),
            selected: Style::new()
                .fg(Fixed(WHITE))
                .on(CATPPUCCIN_SURFACE_0)
                .bold(),
            selected_and_matched: Style::new()
                .fg(Fixed(MAGENTA))
                .underline()
                .on(Fixed(GREY))
                .bold(),
            ellipsized: Style::new().dimmed(),
            selected_and_ellipsized: Style::new().dimmed().on(CATPPUCCIN_SURFACE_0),

            control_background: Style::new().on(GUNMETAL_BACKGROUND),
            control_keycode: Style::new().fg(Fixed(GREEN)).on(GUNMETAL_BACKGROUND).bold(),
            control_label: Style::new().on(GUNMETAL_BACKGROUND).bold(),
        }
    }
}

const RESET: &str = "\x1B[0m";

impl Styles {
    pub(crate) fn fmt_pane_too_small(&self, f: &mut Formatter<'_>) -> Result {
        writeln!(f, "{}", self.error.paint("Plugin pane is too small"))
    }

    pub(crate) fn fmt_user_input(
        &self,
        f: &mut Formatter<'_>,
        prompt: &str,
        input: &str,
    ) -> Result {
        writeln!(
            f,
            "{} {}{}",
            self.prompt.paint(prompt),
            input,
            self.cursor.paint(" ")
        )
    }

    pub(crate) fn fmt_user_input_divider(
        &self,
        f: &mut Formatter<'_>,
        matched: usize,
        total: usize,
        cols: usize,
    ) -> Result {
        let stats = format!("  {}/{}", matched, total);
        let fills = "─".repeat(cols.saturating_sub(stats.len() + 3));

        writeln!(
            f,
            "{} {}",
            self.separator.paint(stats),
            self.separator.paint(fills)
        )
    }

    pub(crate) fn fmt_matched_results(
        &self,
        f: &mut Formatter<'_>,
        matched_results: &Vec<Match>,
        selected_index: usize,
        rows: usize,
        cols: usize,
    ) -> Result {
        let mut ch_buf = [0u8; 4];
        for (index, m) in matched_results.iter().take(rows).enumerate() {
            self.fmt_matched_line(f, &mut ch_buf, m, index == selected_index, cols)?;
        }

        Ok(())
    }

    fn fmt_matched_line(
        &self,
        f: &mut Formatter<'_>,
        ch_buf: &mut [u8; 4],
        m: &Match,
        is_selected: bool,
        cols: usize,
    ) -> Result {
        let cols = cols.saturating_sub(2); // Take into account prefix.

        if cols < 3 {
            unreachable!("rendering function not adequate for narrow screens");
        }

        let (entry, offset) = if m.entry.len() > cols {
            let ridx = cols.saturating_sub(1);
            (
                // m.entry = "abcdef"
                //            012345
                // cols = 5
                // entry[:-4]
                // entry   = "…cdef"
                //             2345
                slice_from_end(&m.entry, ridx.saturating_sub(1))
                    .expect("entry contains at least `cols - 1` characters"),
                m.entry.len().saturating_sub(cols - 1),
            )
        } else {
            (m.entry.as_str(), 0)
        };
        // m.entry = "abcdef"
        // entry   = "cdef"
        let styled_entry = entry
            .char_indices()
            // (0, entry[0]), (1, entry[1]), (2, entry[2]), …
            .map(|(idx, ch)| (idx + offset, ch)) // Reframe indices.
            // (offset, entry[0]), (offset + 1, entry[1]), (offset + 2, entry[2]), …
            .map(|(idx, ch)| {
                let style = match (m.indices.contains(&idx), is_selected) {
                    (true, true) => self.selected_and_matched,
                    (false, true) => self.selected,
                    (true, false) => self.matched,
                    _ => self.none,
                };
                style.paint(ch.encode_utf8(ch_buf) as &str).to_string()
            })
            .collect::<String>();

        let styled_entry = if offset != 0 {
            format!(
                "{}{styled_entry}",
                if is_selected {
                    self.selected_and_ellipsized
                } else {
                    self.ellipsized
                }
                .paint("…")
            )
        } else {
            styled_entry
        };
        if is_selected {
            self.fmt_selected_line(f, &styled_entry)?;
        } else {
            writeln!(f, "  {styled_entry}")?;
        }

        Ok(())
    }

    fn fmt_selected_line(&self, f: &mut Formatter<'_>, entry: &str) -> Result {
        writeln!(
            f,
            "{}{entry}\u{1b}[48;2;49;50;68m\u{1b}[0K",
            self.caret.paint("▌ "),
        )?;
        write!(f, "{}", RESET)
    }

    /// Realistically, the control bar is fully static, so it could be hard-coded as a single
    /// &'static str, but then dealing with horizontal available space and truncation might become
    /// nerve-racking.
    pub(crate) fn fmt_control_bar(
        &self,
        f: &mut Formatter<'_>,
        control_bar: &ControlBar,
        cols: usize,
    ) -> Result {
        let Some(segments) = control_bar.render(self, cols) else {
            return Ok(());
        };

        // Use ANSI escape sequences manually to fill out the line without repeating spaces.
        writeln!(
            f,
            "{}\u{1b}[48;2;29;31;33m\u{1b}[0K",
            ANSIStrings(&segments)
        )?;
        write!(f, "{}", RESET)
    }

    pub(crate) fn fmt_status_bar(&self, f: &mut Formatter<'_>, context: &Context) -> Result {
        let Some(first_error) = context.errors().first() else {
            return Ok(());
        };

        write!(f, "{}: ", self.error.paint("Error"))?;

        if context.errors().len() == 1 {
            write!(f, "{first_error}")
        } else {
            write!(
                f,
                "{first_error}, and {} others",
                context.errors().len() - 1
            )
        }
    }
}

fn slice_from_end(s: &str, n: usize) -> Option<&str> {
    s.char_indices().rev().nth(n).map(|(i, _)| &s[i..])
}

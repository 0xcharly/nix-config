#![allow(dead_code)]

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

    control_background: Style,
    control_keycode: Style,
    control_label: Style,
}

pub(crate) struct ControlSegment<'cs> {
    pub(crate) control: &'cs str,
    pub(crate) label: &'cs str,
}

pub(crate) struct ControlBar<'cb> {
    pub(crate) segments: [ControlSegment<'cb>; 3],
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
const CATPPUCCIN_MANTLE: Colour = RGB(24, 24, 37);

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

            control_background: Style::new().on(CATPPUCCIN_MANTLE),
            control_keycode: Style::new().fg(Fixed(GREEN)).on(CATPPUCCIN_MANTLE).bold(),
            control_label: Style::new().on(CATPPUCCIN_MANTLE).bold(),
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
    ) -> Result {
        let mut ch_buf = [0u8; 2];
        for (index, m) in matched_results.iter().take(rows).enumerate() {
            self.fmt_matched_line(f, &mut ch_buf, m, index == selected_index)?;
        }

        Ok(())
    }

    fn fmt_matched_line(
        &self,
        f: &mut Formatter<'_>,
        ch_buf: &mut [u8; 2],
        m: &Match,
        is_selected: bool,
    ) -> Result {
        let styled_entry = m
            .entry
            .char_indices()
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
            self.caret.paint("> "),
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
    ) -> Result {
        let segment_separators = vec![self.control_background.paint(" / ")];

        // TODO: use std::iter::Itersperse when available.
        // https://doc.rust-lang.org/std/iter/struct.Intersperse.html
        #[allow(unstable_name_collisions)]
        let segments: Vec<ANSIString<'_>> = control_bar
            .segments
            .iter()
            .map(|segment| {
                vec![
                    self.control_background.paint("<"),
                    self.control_keycode.paint(segment.control),
                    self.control_background.paint("> "),
                    self.control_label.paint(segment.label),
                ]
            })
            .intersperse(segment_separators)
            .flatten()
            .collect();

        // Use ANSI escape sequences manually to fill out the line without repeating spaces.
        writeln!(
            f,
            "{}\u{1b}[48;2;24;24;37m\u{1b}[0K",
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

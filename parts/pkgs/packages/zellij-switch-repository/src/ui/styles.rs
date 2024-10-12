#![allow(dead_code)]

use ansi_term::{Colour::Fixed, Style};

use super::Styles;

const GREY: u8 = 0;
const RED: u8 = 1;
const GREEN: u8 = 2;
const YELLOW: u8 = 3;
const BLUE: u8 = 4;
const MAGENTA: u8 = 5;
const CYAN: u8 = 6;
const WHITE: u8 = 7;

impl Default for Styles {
    fn default() -> Self {
        Self {
            none: Style::new(),
            caret: Style::new().fg(Fixed(MAGENTA)).bold(),
            cursor: Style::new().on(Fixed(WHITE)),
            prompt: Style::new().fg(Fixed(MAGENTA)).bold(),
            separator: Style::new().fg(Fixed(CYAN)),
            matched: Style::new().fg(Fixed(MAGENTA)).underline(),
            selected: Style::new().fg(Fixed(WHITE)).on(Fixed(GREY)).bold(),
            selected_and_matched: Style::new()
                .fg(Fixed(MAGENTA))
                .underline()
                .on(Fixed(GREY))
                .bold(),
        }
    }
}

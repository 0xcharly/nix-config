use serde::{Deserialize, Serialize};
use serde_json::Result;
use std::path::PathBuf;

use zellij_tile::prelude::*;

pub struct Config {
    pub layout: LayoutInfo,
}

#[derive(Debug, Clone)]
pub enum SwitchStrategy {
    Unknown,
    Replace,
    CreateNew,
}

#[derive(Debug, Clone)]
pub enum PipeCommand {
    UnknownCommand(String),
    InvalidPayload(String),
    InvalidArguments(String, Option<String>),
    Exec(PathBuf),
    SwitchSession(String, PathBuf),
}

impl Default for SwitchStrategy {
    fn default() -> Self {
        Self::Unknown
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            layout: LayoutInfo::BuiltIn("default".to_string()),
        }
    }
}

impl Default for PipeCommand {
    fn default() -> Self {
        Self::UnknownCommand("init".to_owned())
    }
}

pub fn serialize<T>(value: &T) -> serde_json::Result<String>
where
    T: ?Sized + Serialize,
{
    serde_json::to_string(value)
}

pub fn deserialize<'a, T>(s: &'a str) -> Result<T>
where
    T: Deserialize<'a>,
{
    serde_json::from_str(s)
}

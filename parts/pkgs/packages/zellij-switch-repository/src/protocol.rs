use serde::{Deserialize, Serialize};
use serde_json::Result;
use std::path::PathBuf;

use zellij_tile::prelude::*;

pub struct Config {
    pub root: Option<PathBuf>,
    pub layout: LayoutInfo,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            root: Default::default(),
            layout: LayoutInfo::BuiltIn("default".to_string()),
        }
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

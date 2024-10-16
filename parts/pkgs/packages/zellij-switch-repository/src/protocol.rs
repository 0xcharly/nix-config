use serde::{Deserialize, Serialize};
use serde_json::Result;
use std::path::PathBuf;

use zellij_tile::prelude::*;

pub(crate) struct Config {
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

// TODO: unwrap the JSON-specific error to fully abstract away the serialization methods/format.
pub(crate) fn serialize<T>(value: &T) -> Result<String>
where
    T: ?Sized + Serialize,
{
    serde_json::to_string(value)
}

pub(crate) fn deserialize<'a, T>(s: &'a str) -> Result<T>
where
    T: Deserialize<'a>,
{
    serde_json::from_str(s)
}

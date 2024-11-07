/// Abstracts away the serialization format and toolchain.
use anyhow;
use serde;
use serde_json;

pub(crate) fn serialize<T>(value: &T) -> anyhow::Result<String>
where
    T: ?Sized + serde::Serialize,
{
    Ok(serde_json::to_string(value)?)
}

pub(crate) fn deserialize<'a, T>(s: &'a str) -> anyhow::Result<T>
where
    T: serde::Deserialize<'a>,
{
    Ok(serde_json::from_str(s)?)
}

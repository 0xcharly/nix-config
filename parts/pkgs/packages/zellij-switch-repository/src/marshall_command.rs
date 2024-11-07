/// Abstracts away the serialization format and toolchain.
use anyhow;
use serde;
use rmp_serde;

pub(crate) fn deserialize<'a, T>(s: &'a Vec<u8>) -> anyhow::Result<T>
where
    T: serde::Deserialize<'a>,
{
    Ok(rmp_serde::from_slice(s)?)
}

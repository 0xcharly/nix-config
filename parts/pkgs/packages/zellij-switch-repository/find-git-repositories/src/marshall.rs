/// Abstracts away the serialization format and toolchain.
use anyhow;
use rmp_serde;
use serde;

pub(crate) fn serialize<T>(value: &T) -> anyhow::Result<Vec<u8>>
where
    T: ?Sized + serde::Serialize,
{
    Ok(rmp_serde::to_vec(value)?)
}

use std::path::PathBuf;

use bstr::ByteSlice;
use data_encoding::HEXLOWER;
use sha2::digest;
use std::io;
use zellij_tile::prelude::*;

const HASH_PREFIX_LENGTH: usize = 8;

/// Reads through all data from the passed reader, and returns the resulting [Digest].
/// The exact hash function used is left generic over all [Digest].
fn hash<D: digest::Digest + io::Write>(mut r: impl io::Read) -> Result<digest::Output<D>> {
    let mut hasher = D::new();
    io::copy(&mut r, &mut hasher)?;
    Ok(hasher.finalize())
}

/// Returns a unique and stable session identifier for the given input path.
/// The identifier consists of 2 segments joined by a dash (`-`) character:
///   - a short hash of the path (8 character prefix)
///   - the basename of the path
pub(crate) fn get_session_name(path: &PathBuf) -> Result<String> {
    let fname = path
        .file_name()
        .ok_or_else(|| anyhow!("invalid path (ends with a dot?): {path:?}"))?
        .to_str()
        .ok_or_else(|| anyhow!("failed to decode path (invalid UTF-8?): {path:?}"))?;
    let hashed_path = HEXLOWER.encode(
        hash::<sha1::Sha1>(
            path.to_str()
                .ok_or_else(|| anyhow!("failed to decode path (invalid UTF-8?): {path:?}"))?
                .as_bytes(),
        )?
        .as_bstr(),
    );

    Ok(format!(
        "{}-{fname}",
        hashed_path
            .chars()
            .take(HASH_PREFIX_LENGTH)
            .collect::<String>()
    ))
}

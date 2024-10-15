use std::path::PathBuf;

use bstr::ByteSlice;
use data_encoding::HEXLOWER;
use sha2::{digest::Output, Digest};
use zellij_tile::prelude::*;

const HASH_PREFIX_LENGTH: usize = 8;

/// Reads through all data from the passed reader, and returns the resulting [Digest].
/// The exact hash function used is left generic over all [Digest].
fn hash<D: Digest + std::io::Write>(mut r: impl std::io::Read) -> Result<Output<D>> {
    let mut hasher = D::new();
    std::io::copy(&mut r, &mut hasher)?;
    Ok(hasher.finalize())
}

pub fn get_session_name(path: &PathBuf) -> Result<String> {
    let fname = path
        .file_name()
        .ok_or_else(|| anyhow!("invalid path (ends with a dot?): {:?}", path))?
        .to_str()
        .ok_or_else(|| anyhow!("failed to decode path (invalid UTF-8?): {:?}", path))?;
    let hashed_path = HEXLOWER.encode(
        hash::<sha1::Sha1>(
            path.to_str()
                .ok_or_else(|| anyhow!("failed to decode path (invalid UTF-8?): {:?}", path))?
                .as_bytes(),
        )?
        .as_bstr(),
    );
    eprintln!("hash={}", hashed_path);

    Ok(format!(
        "{}-{}",
        hashed_path
            .chars()
            .take(HASH_PREFIX_LENGTH)
            .collect::<String>(),
        fname
    ))
}

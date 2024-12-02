use super::core::Result;

use std::collections::BTreeMap;
use std::fs;
use std::path::PathBuf;

/// Lists all git repositories under [root]. Stop traversing at [max_depth].
///
/// NOTE: There's no point for this to return an iterator and progressively output matches as they
/// are discovered since Zellij waits for the process to complete before returning all of its
/// output to plugins.
pub(super) fn list_repositories(
    root: &PathBuf,
    max_depth: usize,
) -> Result<BTreeMap<PathBuf, PathBuf>> {
    let mut repositories = BTreeMap::new();
    let mut dirs_to_walk = Vec::new();

    let child_dirs = get_child_directories(root)?;
    if !child_dirs.is_empty() {
        dirs_to_walk.push((root.clone(), child_dirs, /* depth */ 1));
    }

    'outer: while let Some((parent, children, depth)) = dirs_to_walk.pop() {
        assert!(
            children.iter().all(|e| fs::metadata(e)
                .map(|e| e.file_type().is_dir())
                .unwrap_or(false)),
            "internal error: all children must be valid directories"
        );

        for dir in &children {
            if dir
                .file_name()
                .map(|fname| fname == ".git")
                .unwrap_or(false)
            {
                repositories.insert(
                    parent
                        .strip_prefix(root)
                        .expect("`parent` is built from `root`")
                        .to_path_buf(),
                    parent,
                );
                continue 'outer;
            }
        }
        if depth < max_depth {
            for dir in children {
                let Ok(child_dirs) = get_child_directories(&dir) else {
                    // An error occured while traversing directories. Ignore it and continue.
                    continue;
                };
                if !child_dirs.is_empty() {
                    dirs_to_walk.push((dir, child_dirs, depth + 1));
                }
            }
        }
    }

    Ok(repositories)
}

fn get_child_directories(path: &PathBuf) -> Result<Vec<PathBuf>> {
    let mut children = Vec::new();

    let entries = match fs::read_dir(path) {
        Ok(entries) => entries,
        Err(error) => return Err(crate::core::Error::FileSystemReadFailed(error.into())),
    };

    for entry in entries {
        if let Ok(entry) = entry {
            if let Ok(ft) = entry.file_type() {
                if ft.is_dir() {
                    children.push(entry.path());
                }
            }
        }
    }

    Ok(children)
}

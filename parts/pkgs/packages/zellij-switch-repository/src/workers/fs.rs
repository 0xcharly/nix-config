use std::collections::BTreeSet;
use std::fs;
use std::path::PathBuf;

// TODO: Change this to return an iterator instead so that early results are immediately visible.
pub(crate) fn list_repositories(root: &PathBuf, max_depth: usize) -> BTreeSet<PathBuf> {
    let mut repositories = BTreeSet::new();
    let mut dirs_to_walk = Vec::new();

    let child_dirs = get_child_directories(root);
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
                repositories.insert(parent);
                continue 'outer;
            }
        }
        if depth < max_depth {
            for dir in children {
                let child_dirs = get_child_directories(&dir);
                if !child_dirs.is_empty() {
                    dirs_to_walk.push((dir, child_dirs, depth + 1));
                }
            }
        }
    }

    repositories
        .iter()
        .filter_map(|path| path.strip_prefix(root).ok())
        .map(|p| p.to_path_buf())
        .collect::<BTreeSet<_>>()
}

fn get_child_directories(path: &PathBuf) -> Vec<PathBuf> {
    let mut children = Vec::new();

    if let Ok(entries) = fs::read_dir(path) {
        for entry in entries {
            if let Ok(entry) = entry {
                if let Ok(ft) = entry.file_type() {
                    if ft.is_dir() {
                        children.push(entry.path());
                    }
                }
            }
        }
    }

    children
}

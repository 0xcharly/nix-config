/// Implementation of Prime's "sessionizer" script as a Zellij plugin.
///
/// This plugin scans the given root directory and yields a list of git repositories found under
/// it. It displays this list in an interactive picker with fuzzy matching. On selection, it opens
/// a Zellij session with the target directory as CWD.
/// Sessions are given a stable unique name to switch to an existing session if it exists instead
/// of systematically creating new ones.
use zellij_tile::prelude::*;

mod hash;
mod matcher;
mod plugin;
mod marshall;
mod ui;

#[cfg(not(feature = "zellij_fallback_fs_api"))]
mod workers;

register_plugin!(plugin::SwitchRepositoryPlugin);

#[cfg(not(feature = "zellij_fallback_fs_api"))]
register_worker!(
    workers::crawlers::FileSystemWorker,
    file_system_worker,
    FILE_SYSTEM_WORKER
);

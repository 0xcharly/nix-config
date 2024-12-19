use matcher::Choice;
/// Implementation of ThePrimeagen's "sessionizer" script as a Zellij plugin.
///
/// This plugin scans the given root directory and yields a list of git repositories found under
/// it. It displays this list in an interactive picker with fuzzy matching. On selection, it opens
/// a Zellij session with the target directory as CWD.
/// Sessions are given a stable unique name to switch to an existing session if it exists instead
/// of systematically creating new ones.
use zellij_tile::prelude::*;

mod context;
mod core;
mod hash;
#[cfg(feature = "zellij_run_command_api")]
mod marshall_command;
#[cfg(not(feature = "zellij_fallback_fs_api"))]
mod marshall_plugin;
mod matcher;
mod plugin;
mod protocol;
mod ui;
#[cfg(not(feature = "zellij_fallback_fs_api"))]
mod workers;

// Registers the plugin against the Zellij API.
register_plugin!(plugin::PathFinderPlugin);

// Registers the background FS crawler worker against the Zellij API.
// This worker uses the regular WASI FS API to look for repositories.
// According to Zellij's documentation, scanning the FS through their WASI runtime is "extremely
// slow". For this reason, they provide a "stop-gap method that allows plugins to scan a folder on
// the /host filesystem and get back a list of files". This plugin supports both APIs, and defaults
// to using the regular WASI runtime. Enable feature `zellij_fallback_fs_api` to switch to Zellij's
// custom (and supposedly temporary) API.
// See https://zellij.dev/documentation/plugin-api-commands#scan_host_folder.
#[cfg(not(feature = "zellij_fallback_fs_api"))]
register_worker!(
    workers::crawlers::FileSystemWorker,
    file_system_worker,
    FILE_SYSTEM_WORKER
);

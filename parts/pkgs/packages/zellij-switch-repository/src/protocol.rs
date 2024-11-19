use crate::core::PluginError;

use std::{collections::BTreeMap, path::PathBuf};
use zellij_tile::prelude::{LayoutInfo, PipeMessage};

// This structure mostly exists because `LayoutInfo` doesn't implement the `Default` trait.
pub(super) struct PathFinderPluginConfig {
    pub(super) layout: LayoutInfo,
    pub(super) cwd: Option<PathBuf>,
    pub(super) caller_cwd: Option<PathBuf>,
    pub(super) pathfinder_root: Option<PathBuf>,
    pub(super) external_pathfinder_command: Option<PathBuf>,

    pub(super) bootstrap: bool,
}

// Configuration.

/// See https://zellij.dev/documentation/plugin-aliases.html?highlight=caller#a-note-about-cwd.
const ZELLIJ_CALLER_CURRENT_WORKING_DIR: &'static str = "caller_cwd";
const ZELLIJ_PLUGIN_CURRENT_WORKING_DIR: &'static str = "cwd";
const REPOSITORY_PATHFINDER_ROOT_OPTION: &'static str = "repository_pathfinder_root";
const EXTERNAL_PATHFINDER_COMMAND_OPTION: &'static str = "pathfinder_command";

const BOOTSTRAP_OPTION: &'static str = "bootstrap";

impl PathFinderPluginConfig {
    pub(super) fn load(&mut self, configuration: &BTreeMap<String, String>) {
        self.cwd = configuration
            .get(ZELLIJ_PLUGIN_CURRENT_WORKING_DIR)
            .map(PathBuf::from);
        self.caller_cwd = configuration
            .get(ZELLIJ_CALLER_CURRENT_WORKING_DIR)
            .map(PathBuf::from);
        self.pathfinder_root = configuration
            .get(REPOSITORY_PATHFINDER_ROOT_OPTION)
            .map(PathBuf::from);
        self.external_pathfinder_command = configuration
            .get(EXTERNAL_PATHFINDER_COMMAND_OPTION)
            .map(PathBuf::from);

        self.bootstrap = configuration
            .get(BOOTSTRAP_OPTION)
            .map_or(false, |val| val.parse().unwrap());
    }
}

impl Default for PathFinderPluginConfig {
    fn default() -> Self {
        Self {
            layout: LayoutInfo::BuiltIn("default".to_string()),
            cwd: Default::default(),
            caller_cwd: Default::default(),
            pathfinder_root: Default::default(),
            external_pathfinder_command: Default::default(),
            bootstrap: Default::default(),
        }
    }
}

// Pipe Messages.

/// The plugin configuration message name to pass to request using the builtin API to scan the
/// plugin's CWD and look for Git repositories.
///
/// ```kdl
/// MessagePlugin "pathfinder" {
///   cwd "/path/to/root/to/scan"
///   name "scan_repository_root"
///   launch_new true
/// }
/// ```
///
/// Note that `launch_new` is required to guarantee that the plugin is restarted with the correct
/// CWD: Zellij plugins are jailed under their CWD, and cannot access the filesystem beyond it.
const PATHFINDER_COMMAND_SCAN_REPOSITORY_ROOT: &'static str = "scan_repository_root";

/// The plugin configuration message name to pass to request calling an external program to list
/// directories. This message expects an associated payload that is the absolute path to the cli
/// program to invoke.
///
/// ```kdl
/// MessagePlugin "pathfinder" {
///   name "run_external_program"
///   payload "/path/to/program/to/run"
/// }
/// ```
const PATHFINDER_COMMAND_RUN_EXTERNAL_PROGRAM: &'static str = "run_external_program";

#[derive(Debug)]
pub(super) enum PathFinderPluginCommand {
    PluginCommandError(PluginError),
    ScanRepositoryRoot,
    RunExternalProgram(PathBuf),
}

impl From<PipeMessage> for PathFinderPluginCommand {
    fn from(message: PipeMessage) -> Self {
        use PathFinderPluginCommand::*;
        use PluginError::MissingPipeMessagePayloadError;
        use PluginError::UnknownPipeMessageError;

        match message.name.as_ref() {
            PATHFINDER_COMMAND_SCAN_REPOSITORY_ROOT => ScanRepositoryRoot,
            PATHFINDER_COMMAND_RUN_EXTERNAL_PROGRAM => match message.payload {
                Some(payload) => RunExternalProgram(PathBuf::from(payload)),
                _ => PluginCommandError(MissingPipeMessagePayloadError(message.name)),
            },
            _ => PluginCommandError(UnknownPipeMessageError(message.name)),
        }
    }
}

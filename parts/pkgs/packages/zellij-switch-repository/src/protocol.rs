use crate::core::PluginError;

use std::{collections::BTreeMap, path::PathBuf};
use zellij_tile::{
    prelude::{LayoutInfo, PipeMessage, PipeSource},
    shim::get_plugin_ids,
};

// This structure mostly exists because `LayoutInfo` doesn't implement the `Default` trait.
#[derive(Debug)]
pub(super) struct PathFinderPluginConfig {
    pub(super) layout: LayoutInfo,
    pub(super) pathfinder_root: Option<PathBuf>,
    pub(super) external_pathfinder_command: Option<PathBuf>,

    /// Synthesized from the plugin startup configuration if it contains a `name` key.
    pub(super) pipe_message: Option<PipeMessage>,
    /// Whether to automatically kill the session after switching.
    /// This is set to `true` in [PathFinderPluginConfig.load] if `pipe_message` is not `None`.
    pub(super) kill_after_switch: bool,
}

// Configuration.

/// See https://zellij.dev/documentation/plugin-aliases.html?highlight=caller#a-note-about-cwd.
const REPOSITORY_PATHFINDER_ROOT_OPTION: &'static str = "repository_pathfinder_root";
const EXTERNAL_PATHFINDER_COMMAND_OPTION: &'static str = "pathfinder_command";

impl PathFinderPluginConfig {
    pub(super) fn load(&mut self, configuration: &BTreeMap<String, String>) {
        self.pathfinder_root = configuration
            .get(REPOSITORY_PATHFINDER_ROOT_OPTION)
            .map(PathBuf::from);
        self.external_pathfinder_command = configuration
            .get(EXTERNAL_PATHFINDER_COMMAND_OPTION)
            .map(PathBuf::from);

        self.pipe_message = synthesize_pipe_message(configuration);
        self.kill_after_switch = self.pipe_message.is_some();
    }
}

/// `name` is a reserved key, among others:
/// https://github.com/zellij-org/zellij/blob/afd4c644bc682df1bd9b06e575611aceb5e8c4a7/zellij-utils/src/input/layout.rs#L504-L516
const STARTUP_MESSAGE_NAME: &'static str = "startup_message_name";
const STARTUP_MESSAGE_PAYLOAD: &'static str = "startup_message_payload";

/// Synthesize a [PipeMessage] from the plugin config.
/// Returns `None` if `configuration` does not contain a `name` key.
fn synthesize_pipe_message(configuration: &BTreeMap<String, String>) -> Option<PipeMessage> {
    configuration.get(STARTUP_MESSAGE_NAME).map(|name| PipeMessage {
        source: PipeSource::Plugin(get_plugin_ids().plugin_id),
        name: name.to_owned(),
        payload: configuration.get(STARTUP_MESSAGE_PAYLOAD).map(|p| p.to_owned()),
        args: Default::default(),
        is_private: true,
    })
}

impl Default for PathFinderPluginConfig {
    fn default() -> Self {
        Self {
            layout: LayoutInfo::BuiltIn("default".to_string()),
            pathfinder_root: Default::default(),
            external_pathfinder_command: Default::default(),
            pipe_message: Default::default(),
            kill_after_switch: false,
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

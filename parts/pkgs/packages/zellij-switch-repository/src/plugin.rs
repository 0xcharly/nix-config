use crate::context;
use crate::core::{InternalError, PluginError, PluginUpdateLoop, Result, ResultIterator};
use crate::hash;
#[cfg(not(any(feature = "zellij_fallback_fs_api", feature = "zellij_run_command_api")))]
use crate::marshall::{deserialize, serialize};
use crate::matcher::RepositoryMatcher;
use crate::ui::{Renderer, PANE_TITLE};
#[cfg(not(any(feature = "zellij_fallback_fs_api", feature = "zellij_run_command_api")))]
use crate::workers::protocol::{
    FileSystemWorkerMessage, RepositoryCrawlerRequest, RepositoryCrawlerResponse,
};

use anyhow::Context;
use std::{
    collections::{BTreeMap, BTreeSet},
    path::PathBuf,
};
use zellij_tile::prelude::*;

/// The plugin state, to be registered against Zellij's API.
///
/// It contains the plugin's user configuration, as well as cached state used for operating
/// purposes.
///
/// `current_session_name` and `all_sessions_name` must be known before switching to a other
/// session. The rational is twofold:
///
///   - For esthetic purposes: Zellij fails to switch to the current session, and we can do a
///     better job at reporting this error case ourselves.
///   - For ergonomic purposes: to suppress the current directory from the list of candidates.
///
/// While these values can only be known after receiving an asynchronous `Event::SessionUpdate`
/// event and can thus cause Zellij to error out if we're trying to switch to the current session
/// before being able to verify that this is the case, in practice Zellij always sends such event
/// much faster than our filesystem crawler returns results, and a fortiori much, much faster than
/// our user can select any input. For this reason, we do not bother blocking waiting for these
/// values and assume that they are always already available by the time the user validates their
/// input.
///
/// On the other hand, `permissions_granted` keeps track of whether the plugin has the necessary
/// permissions to run correctly, and this is directly gated by user input (review and validation
/// request that it is OK to grant these permissions to a plugin). As such, we're queueing all
/// events received before permissions were granted and process them only after that. Such queued
/// events are stored in `event_queue`.
///
/// `matchers` and `renderer` handle the operating aspects of this plugin, respectively user input
/// and plugin UI.
///
/// NOTE: it would be ideal if we could declare lifetimes bound to this structure, but these are
/// unfortunately incompatible with the current Zellij API.
#[derive(Default)]
pub(crate) struct SwitchRepositoryPlugin {
    /// Configuration passed to the plugin at initialization time (i.e. via a KDL configuration file
    /// of via the `--configuration` commandline switch.
    config: SwitchRepositoryPluginConfig,

    // We receive these via the `Event::SessionUdate` event. They are required for switching
    // session (because Zellij does not appreciate switching to the current session).
    /// The name of the session the plugin is running in.
    current_session_name: Option<String>,
    /// The name of all sessions managed by the Zellij daemon serving the session the plugin is
    /// running in.
    all_sessions_name: BTreeSet<String>,

    /// All permissions are required to fulfil our purpose.
    permissions_granted: bool,
    /// Events queued until the first `Event::SessionUpdate` is received.
    event_queue: Vec<Event>,

    /// The plugin context, that keeps track of some volatile state.
    context: context::Context,
    /// Matches the list of repositories against the user input. Keeps track of the user input.
    matcher: RepositoryMatcher,
    /// Handles drawing the list of results on the screen, as well as dealing with user selection.
    renderer: Renderer,
}

// This structure mostly exists because `LayoutInfo` doesn't implement the `Default` trait.
struct SwitchRepositoryPluginConfig {
    layout: LayoutInfo,
    root: Option<PathBuf>,
    list_directories_command: Option<PathBuf>,
}

impl SwitchRepositoryPluginConfig {
    fn load(&mut self, configuration: &BTreeMap<String, String>) {
        self.root = configuration.get("repositories_root").map(PathBuf::from);
        self.list_directories_command = configuration
            .get("get_directory_list_command")
            .map(PathBuf::from);
    }
}

impl Default for SwitchRepositoryPluginConfig {
    fn default() -> Self {
        Self {
            layout: LayoutInfo::BuiltIn("default".to_string()),
            root: Default::default(),
            list_directories_command: Default::default(),
        }
    }
}

impl ZellijPlugin for SwitchRepositoryPlugin {
    // Plugin entry point.
    //
    // Called by Zellij when the plugin is loaded into a session.
    // Requests the required permissions and install asynchronous handlers to deal with requests
    // responses.
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        // [ChangeApplicationState] is required for logging to Zellij's log, for switching session,
        // and for renaming panes.
        request_permission(&[
            PermissionType::ChangeApplicationState,
            PermissionType::ReadApplicationState,
            #[cfg(feature = "zellij_run_command_api")]
            PermissionType::RunCommands,
        ]);
        subscribe(&[
            EventType::CustomMessage,
            #[cfg(feature = "zellij_fallback_fs_api")]
            EventType::FileSystemUpdate,
            EventType::Key,
            EventType::PermissionRequestResult,
            #[cfg(feature = "zellij_run_command_api")]
            EventType::RunCommandResult,
            EventType::SessionUpdate,
        ]);

        self.config.load(&configuration);

        if self.permissions_granted {
            // Initialize the plugin immediatelly since permissions have already been granted.
            self.on_permissions_granted();
        }
    }

    fn update(&mut self, event: Event) -> bool {
        let result = if let Event::PermissionRequestResult(PermissionStatus::Granted) = event {
            self.permissions_granted = true;
            self.on_permissions_granted();
            self.drain_events()
        } else if self.permissions_granted {
            self.handle_event(event)
        } else {
            self.event_queue.push(event);
            return false; // No need to update the UI.
        };

        self.process_result(result)
    }

    fn render(&mut self, rows: usize, cols: usize) {
        let frame = self
            .renderer
            .next_frame(rows, cols, &self.context, &self.matcher);
        print!("{}", frame);
    }
}

impl SwitchRepositoryPlugin {
    fn process_result(&mut self, result: Result) -> bool {
        match result {
            Ok(strategy) => strategy,
            Err(error) => {
                eprintln!("unexpected error: {error:?}");
                self.context
                    .log_error(PluginError::UnexpectedError(error.into()))
            }
        }
        .as_bool()
    }

    fn on_permissions_granted(&mut self) -> PluginUpdateLoop {
        // Give the plugin pane a more concise name.
        rename_plugin_pane(get_plugin_ids().plugin_id, PANE_TITLE);

        // Start scanning the /host. The scan always happens asynchronously, and responses are
        // posted back to the plugin through the `::update(…)` callback.
        // The scanning method (either through a background plugin worker or via the Zellij API) is
        // dictated by the `zellij_fallback_fs_api` feature flag.
        if let Err(error) = self.start_async_root_scan() {
            self.context
                .log_error(PluginError::FileSystemScanFailed(error))
        } else {
            PluginUpdateLoop::NoUpdates
        }
    }

    fn start_async_root_scan(&self) -> anyhow::Result<()> {
        // TODO: pass these arguments through plugin configuration.
        self.post_repository_crawler_task(PathBuf::from("/host"), /* max_depth */ 5)
    }

    #[cfg(not(any(feature = "zellij_fallback_fs_api", feature = "zellij_run_command_api")))]
    fn post_repository_crawler_task(&self, root: PathBuf, max_depth: usize) -> anyhow::Result<()> {
        // Scan the host folder using the FS worker (preferred).
        // This API posts its results back to the plugin using the `Event::CustomMessage` event
        // with a `FileSystemWorkerMessage::Crawl` message.
        // NOTE: The `PluginMessage::new_to_worker(…)`'s `worker_name` argument must match the
        // worker's namespace specified when registering the worker: to send messages to the worker
        // declared with `test_worker` namespace, pass `"test"` to `::new_to_worker(…)`.
        post_message_to(PluginMessage::new_to_worker(
            "file_system", // Post to the `file_system_worker` namespace.
            &serialize(&FileSystemWorkerMessage::Crawl)
                .with_context(|| "serializing outbound message to `file_system` worker")?,
            &serialize(&RepositoryCrawlerRequest { root, max_depth })
                .with_context(|| "serializing outbound request to `file_system` worker")?,
        ));

        Ok(())
    }

    #[cfg(feature = "zellij_fallback_fs_api")]
    fn post_repository_crawler_task(&self, root: PathBuf, _max_depth: usize) -> anyhow::Result<()> {
        // Scan the host folder with the async `scan_host_folder` API (workaround). This API posts
        // its results back to the plugin using the `Event::FileSystemUpdate` event (see
        // `State::handle_event(…)`).
        // NOTE: This API  is a stop-gap method that allows plugins to scan a folder on the /host
        // filesystem and get back a list of files. This is a workaround for the Zellij WASI
        // runtime being extremely slow. This API might be removed in the future.
        scan_host_folder(&root);

        Ok(())
    }

    #[cfg(feature = "zellij_run_command_api")]
    fn post_repository_crawler_task(
        &self,
        _root: PathBuf,
        _max_depth: usize,
    ) -> anyhow::Result<()> {
        let Some(command) = &self.config.list_directories_command else {
            return Err(PluginError::ConfigurationError {
                reason: "missing `list_directories_command`",
            }
            .into());
        };

        let Some(command) = command.to_str() else {
            return Err(PluginError::FileSystemScanFailed(anyhow!(
                "failed to decode `list_directories_command`"
            ))
            .into());
        };
        run_command(&[&command], BTreeMap::new());

        Ok(())
    }

    /// Consumes as many of the queued events as possible, and returns either the final combined
    /// [RenderStrategy] value, or the first error that occurred.
    ///
    /// If an error occurs, it is propagated back to the caller immediately (short-circuiting). All
    /// remaining queued events are dropped.
    fn drain_events(&mut self) -> Result {
        std::mem::take(&mut self.event_queue)
            .into_iter()
            .map(|event| self.handle_event(event))
            .try_consume()
    }

    #[cfg(not(any(feature = "zellij_fallback_fs_api", feature = "zellij_run_command_api")))]
    fn handle_custom_message(&mut self, message: String, payload: String) {
        assert!(
            matches!(
                deserialize(&message)
                    .with_context(|| "deserializing message from `file_system` worker")?,
                FileSystemWorkerMessage::Crawl
            ),
            "unsupported message received from own background worker"
        );
        let RepositoryCrawlerResponse { repository } = deserialize(&payload)
            .with_context(|| "deserializing response from `file_system` worker")?;
        self.matcher.add_choice(repository);

        Ok(PluginUpdateLoop::MarkDirty)
    }

    #[cfg(feature = "zellij_fallback_fs_api")]
    fn handle_filesystem_update(&mut self, paths: Vec<(PathBuf, Option<FileMetadata>)>) {
        let has_dot_git_dir = paths.iter().any(|(path, metadata)| {
            path.file_name()
                .map(|fname| fname.to_str() == Some(".git"))
                .unwrap_or(false)
                && metadata.map(|m| m.is_dir).unwrap_or(false)
        });
        if has_dot_git_dir {
            let parent = paths
                .first()
                .expect("`paths` is guaranteed to contain at least 1 child")
                .0
                .parent()
                .expect("`parent` is guaranteed to exist")
                .to_path_buf()
                .strip_prefix(PathBuf::from("/host"))
                .expect("path is guaranteed to start with the above prefix")
                .to_path_buf();
            self.matcher.add_choice(parent);
        } else {
            paths
                .iter()
                .filter_map(|(path, metadata)| {
                    metadata
                        .map(|m| if m.is_dir { Some(path) } else { None })
                        .unwrap_or_default()
                })
                .for_each(scan_host_folder);
        }

        Ok(has_dot_git_dir.into())
    }

    #[cfg(feature = "zellij_run_command_api")]
    fn handle_list_directories_command_result(
        &mut self,
        exitcode: Option<i32>,
        stdout: Vec<u8>,
        stderr: Vec<u8>,
    ) -> Result {
        let Some(exitcode) = exitcode else {
            return self
                .context
                .log_error(PluginError::FileSystemScanFailed(anyhow!(
                    "`list_directories_command` failed without exitcode (killed by signal?): {stderr:?}"
                )))
                .into();
        };
        if exitcode != 0 {
            return self
                .context
                .log_error(PluginError::FileSystemScanFailed(anyhow!(
                    "`list_directories_command` failed with exitcode {exitcode}"
                )))
                .into();
        }

        let Ok(stdout) = String::from_utf8(stdout)
            .map_err(|non_utf8| String::from_utf8_lossy(non_utf8.as_bytes()).into_owned())
        else {
            return self
                .context
                .log_error(PluginError::FileSystemScanFailed(anyhow!(
                    "failed to decode `list_directories_command`'s output"
                )))
                .into();
        };
        stdout
            .lines()
            .map(PathBuf::from)
            .for_each(|path| self.matcher.add_choice(path));

        Ok(PluginUpdateLoop::MarkDirty)
    }

    fn handle_event(&mut self, event: Event) -> Result {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                unreachable!("Already handled in `update(event)`");
            }
            Event::PermissionRequestResult(PermissionStatus::Denied) => {
                self.permissions_granted = false;
                Ok(self.terminate())
            }
            #[cfg(not(any(
                feature = "zellij_fallback_fs_api",
                feature = "zellij_run_command_api"
            )))]
            Event::CustomMessage(message, payload) => self.handle_custom_message(message, payload),
            #[cfg(feature = "zellij_fallback_fs_api")]
            Event::FileSystemUpdate(paths) => self.handle_filesystem_update(paths),
            #[cfg(feature = "zellij_run_command_api")]
            Event::RunCommandResult(exitcode, stdout, stderr, _context) => {
                self.handle_list_directories_command_result(exitcode, stdout, stderr)
            }
            Event::SessionUpdate(sessions, _) => {
                self.all_sessions_name = sessions
                    .into_iter()
                    .inspect(|session| {
                        if session.is_current_session {
                            self.current_session_name = Some(session.name.clone());
                        }
                    })
                    .map(|session| session.name)
                    .collect();
                Ok(PluginUpdateLoop::NoUpdates)
            }
            // Clear reported errors on all user inputs.
            // NOTE: use the non-short-circuiting variant of the OR operator to force
            // evaluation of the rhs.
            Event::Key(Key::Up) => {
                self.context.clear_errors() | self.renderer.select_up(&self.matcher)
            }
            Event::Key(Key::Down) => {
                self.context.clear_errors() | self.renderer.select_down(&self.matcher)
            }
            Event::Key(Key::Ctrl('c')) => self.terminate().into(),
            Event::Key(Key::Esc) => Ok(self.context.clear_errors()
                | self.matcher.clear_user_input().or_else(|| self.terminate())),
            Event::Key(Key::Backspace) => {
                Ok(self.context.clear_errors() | self.matcher.remove_trailing_char())
            }
            Event::Key(Key::Char('\n')) => self.context.clear_errors() | self.submit(),
            Event::Key(Key::Char(ch)) => {
                self.context.clear_errors()
                    | self.matcher.on_user_input(ch)
                    | self.renderer.on_user_input(&self.matcher)
            }
            _ => Ok(PluginUpdateLoop::NoUpdates),
        }
    }

    fn terminate(&self) -> PluginUpdateLoop {
        close_self();
        PluginUpdateLoop::NoUpdates
    }

    fn submit(&mut self) -> Result {
        let index = self.renderer.get_selected_index();
        let Some(selected) = self.matcher.matches.get(self.renderer.get_selected_index()) else {
            return Err(InternalError::SelectionIndexOutOfBounds(index).into());
        };
        self.safe_switch_session(PathBuf::from(&selected.entry))
    }

    fn safe_switch_session(&mut self, relative_cwd: PathBuf) -> Result {
        let session_name =
            hash::get_session_name(&relative_cwd).with_context(|| "deriving the session name")?;

        // We have to wait for the `Event::SessionUpdate` event to get the list of existing
        // sessions as well as the name of the current session.
        // NOTE: we _could_ queue up the "switch session" action if the current session name is
        // still unknown at this point. However, realistically, we should have received a
        // `SessionUpdate` event before our fs crawler yields any result. If we haven't something
        // else is going terribly wrong.
        let Some(current_session_name) = self.current_session_name.as_ref() else {
            return self
                .context
                .log_error(PluginError::SwitchSessionFailed {
                    session_name,
                    reason: "unknown current session name",
                })
                .into();
        };

        // TODO: this class of error should be prevented by filtering the current session out of
        // the list, or by silently closing the plugin pane.
        if *current_session_name == session_name {
            return self
                .context
                .log_error(PluginError::SwitchSessionFailed {
                    session_name,
                    reason: "already on target session",
                })
                .into();
        }

        let Some(cwd) = self.config.root.as_ref() else {
            return self
                .context
                .log_error(PluginError::ConfigurationError {
                    reason: "missing root directory declaration",
                })
                .into();
        };

        let cwd = cwd.join(relative_cwd);
        switch_session_with_layout(Some(&session_name), self.config.layout.clone(), Some(cwd));

        // TODO: kill previous session if it was started just to run this plugin.
        // We should have 2 options in such case:
        //   - take over current session (rename and change cwd): impossible because there's no API
        //     to change the cwd of a session.
        //   - switch session and kill previous one: defaulting to this, but need to find a way to
        //     pipe down the info about current session (i.e. whether it's temporary).
        //
        // if !self.all_sessions_name.contains(&session_name) {
        //     kill_sessions(&[current_session_name]);
        // }

        self.terminate().into()
    }
}

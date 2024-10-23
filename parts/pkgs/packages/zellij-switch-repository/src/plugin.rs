use crate::core::{InternalError, PluginError, Result, ResultIteratorOps};
use crate::hash;
#[cfg(not(feature = "zellij_fallback_fs_api"))]
use crate::marshall::{deserialize, serialize};
use crate::matcher::RepositoryMatcher;
use crate::ui::{RenderStrategy, Renderer, PANE_TITLE};
#[cfg(not(feature = "zellij_fallback_fs_api"))]
use crate::workers::protocol::{
    FileSystemWorkerMessage, RepositoryCrawlerRequest, RepositoryCrawlerResponse,
};

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

    /// Matches the list of repositories against the user input. Keeps track of the user input.
    matcher: RepositoryMatcher,
    /// Handles drawing the list of results on the screen, as well as dealing with user selection.
    renderer: Renderer,
}

// This structure mostly exists because `LayoutInfo` doesn't implement the `Default` trait.
struct SwitchRepositoryPluginConfig {
    layout: LayoutInfo,
    root: Option<PathBuf>,
}

impl Default for SwitchRepositoryPluginConfig {
    fn default() -> Self {
        Self {
            layout: LayoutInfo::BuiltIn("default".to_string()),
            root: Default::default(),
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
        ]);
        subscribe(&[
            EventType::CustomMessage,
            #[cfg(feature = "zellij_fallback_fs_api")]
            EventType::FileSystemUpdate,
            EventType::Key,
            EventType::PermissionRequestResult,
            EventType::SessionUpdate,
        ]);

        self.config.root = configuration.get("repositories_root").map(PathBuf::from);

        if self.permissions_granted {
            // Initialize the plugin immediatelly since permissions have already been granted.
            self.on_permissions_granted();

            // Hide the plugin window. It's just meant to be running in the background and
            // listening to focus events.
            hide_self();
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
            Ok(RenderStrategy::SkipNextFrame)
        };

        self.process_result(result)
    }

    fn render(&mut self, rows: usize, cols: usize) {
        let frame = self.renderer.next_frame(rows, cols, &self.matcher);
        println!("{}", frame);
    }
}

impl SwitchRepositoryPlugin {
    fn process_result(&self, result: Result) -> bool {
        // TODO: match error case and display error.
        match result {
            Ok(RenderStrategy::DrawNextFrame) => true,
            _ => false,
        }
    }

    fn on_permissions_granted(&self) {
        // Give the plugin pane a more concise name.
        rename_plugin_pane(get_plugin_ids().plugin_id, PANE_TITLE);

        // Start scanning the /host. The scan always happens asynchronously, and responses are
        // posted back to the plugin through the `::update(…)` callback.
        // The scanning method (either through a background plugin worker or via the Zellij API) is
        // dictated by the `zellij_fallback_fs_api` feature flag.
        if let Err(error) = self.start_async_root_scan() {
            eprintln!("Failed to start repository scan: {error:?}");
        }
    }

    fn start_async_root_scan(&self) -> Result {
        self.post_repository_crawler_task(PathBuf::from("/host"), /* max_depth */ 5)
    }

    #[cfg(feature = "zellij_fallback_fs_api")]
    fn post_repository_crawler_task(&self, root: PathBuf, _max_depth: usize) -> Result {
        // Scan the host folder with the async `scan_host_folder` API (workaround). This API posts
        // its results back to the plugin using the `Event::FileSystemUpdate` event (see
        // `State::handle_event(…)`).
        // NOTE: This API  is a stop-gap method that allows plugins to scan a folder on the /host
        // filesystem and get back a list of files. This is a workaround for the Zellij WASI
        // runtime being extremely slow. This API might be removed in the future.
        scan_host_folder(&root);

        Ok(RenderStrategy::SkipNextFrame)
    }

    #[cfg(not(feature = "zellij_fallback_fs_api"))]
    fn post_repository_crawler_task(&self, root: PathBuf, max_depth: usize) -> Result {
        // Scan the host folder using the FS worker (preferred).
        // This API posts its results back to the plugin using the `Event::CustomMessage` event
        // with a `FileSystemWorkerMessage::Crawl` message.
        // NOTE: The `PluginMessage::new_to_worker(…)`'s `worker_name` argument must match the
        // worker's namespace specified when registering the worker: to send messages to the worker
        // declared with `test_worker` namespace, pass `"test"` to `::new_to_worker(…)`.
        // TODO: report errors to the user through the UI.
        post_message_to(PluginMessage::new_to_worker(
            "file_system", // Post to the `file_system_worker` namespace.
            &serialize(&FileSystemWorkerMessage::Crawl)
                .with_context(|| "serializing outbound message to `file_system` worker")?,
            &serialize(&RepositoryCrawlerRequest { root, max_depth })
                .with_context(|| "serializing outbound request to `file_system` worker")?,
        ));

        Ok(RenderStrategy::SkipNextFrame)
    }

    fn drain_events(&mut self) -> Result {
        if self.event_queue.is_empty() {
            return Ok(RenderStrategy::SkipNextFrame);
        }
        let event_queue = std::mem::take(&mut self.event_queue);
        event_queue
            .into_iter()
            .map(|event| self.handle_event(event))
            .conflate_results()
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
            #[cfg(not(feature = "zellij_fallback_fs_api"))]
            Event::CustomMessage(message, payload) => {
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
                Ok(RenderStrategy::DrawNextFrame)
            }
            #[cfg(feature = "zellij_fallback_fs_api")]
            Event::FileSystemUpdate(paths) => {
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
                Ok(RenderStrategy::SkipNextFrame)
            }
            Event::Key(Key::Up) => self.renderer.select_up(&self.matcher),
            Event::Key(Key::Down) => self.renderer.select_down(&self.matcher),
            Event::Key(Key::Ctrl('c')) => Ok(self.terminate()),
            Event::Key(Key::Esc) => Ok(self
                .matcher
                .clear_user_input()?
                .or_else(|| self.terminate())),
            Event::Key(Key::Backspace) => self.matcher.remove_trailing_char(),
            Event::Key(Key::Char('\n')) => self.submit(),
            Event::Key(Key::Char(ch)) => {
                // NOTE: use the non-short-circuiting variant of the OR operator to force
                // evaluation of the rhs.
                Ok(self.matcher.on_user_input(ch)? | self.renderer.on_user_input(&self.matcher)?)
            }
            _ => Ok(RenderStrategy::SkipNextFrame),
        }
    }

    fn terminate(&self) -> RenderStrategy {
        close_self();
        RenderStrategy::SkipNextFrame
    }

    fn submit(&mut self) -> Result {
        let index = self.renderer.get_selected_index();
        let Some(selected) = self.matcher.matches.get(self.renderer.get_selected_index()) else {
            return Err(InternalError::InvalidIndex(index).into());
        };
        self.safe_switch_session(PathBuf::from(&selected.entry))
    }

    fn safe_switch_session(&self, relative_cwd: PathBuf) -> Result {
        let session_name =
            hash::get_session_name(&relative_cwd).with_context(|| "deriving the session name")?;

        // We have to wait for the `Event::SessionUpdate` event to get the list of existing
        // sessions as well as the name of the current session.
        // NOTE: we _could_ queue up the "switch session" action if the current session name is
        // still unknown at this point. However, realistically, we should have received a
        // `SessionUpdate` event before our fs crawler yields any result. If we haven't something
        // else is going terribly wrong.
        let Some(current_session_name) = self.current_session_name.as_ref() else {
            return Err(PluginError::SwitchSessionFailed {
                session_name,
                reason: "unknown current session name",
            }
            .into());
        };

        if *current_session_name == session_name {
            return Err(PluginError::SwitchSessionFailed {
                session_name,
                reason: "already on target session",
            }
            .into());
        }

        let Some(cwd) = self.config.root.as_ref() else {
            return Err(PluginError::ConfigurationError {
                reason: "missing root directory declaration",
            }
            .into());
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

        Ok(self.terminate())
    }
}

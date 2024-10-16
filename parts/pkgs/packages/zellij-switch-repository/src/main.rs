use matcher::RepositoryMatcher;
use protocol::{deserialize, serialize, Config};
use ui::{Renderer, Rerender};
use workers::protocol::{
    FileSystemWorkerMessage, RepositoryCrawlerRequest, RepositoryCrawlerResponse,
};
use zellij_tile::prelude::*;

use std::{
    collections::{BTreeMap, BTreeSet},
    path::PathBuf,
};
use workers::crawlers::FileSystemWorker;

mod hash;
mod matcher;
mod protocol;
mod ui;
mod workers;

#[derive(Default)]
struct State {
    config: Config,

    // We receive these via the `Event::SessionUdate` event. They are required for switching
    // session (because Zellij does not appreciate switching to the current session).
    current_session_name: Option<String>,
    all_sessions_name: BTreeSet<String>,

    // All permissions are required to perform our purpose.
    permissions_granted: bool,
    // Events queued until `PermissionType::RunCommands` is provided.
    queued_events: Vec<Event>,

    // Matches the list of repositories against the user input. Keeps track of the user input.
    matcher: RepositoryMatcher,
    // Handles drawing the list of results on the screen, as well as user selection.
    renderer: Renderer,
}

register_plugin!(State);
register_worker!(FileSystemWorker, file_system_worker, FILE_SYSTEM_WORKER);

impl ZellijPlugin for State {
    // Plugin entry point.
    //
    // Called by Zellij when the plugin is loaded into a session.
    // Requests the required permissions and install asynchronous handlers to deal with requests
    // responses.
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        // [ChangeApplicationState] is required for logging to Zellij's log, and for switching
        // session.
        request_permission(&[
            PermissionType::ChangeApplicationState,
            PermissionType::ReadApplicationState,
        ]);
        subscribe(&[
            EventType::CustomMessage,
            EventType::FileSystemUpdate,
            EventType::Key,
            EventType::PermissionRequestResult,
            EventType::SessionUpdate,
        ]);

        self.config.root = configuration.get("repositories_root").map(PathBuf::from);

        if self.permissions_granted {
            // Start scanning immediatelly since permissions have already been granted.
            self.start_async_root_scan();

            // Hide the plugin window. It's just meant to be running in the background and
            // listening to focus events.
            hide_self();
        }
    }

    fn update(&mut self, event: Event) -> bool {
        let rerender = if let Event::PermissionRequestResult(PermissionStatus::Granted) = event {
            self.permissions_granted = true;
            self.start_async_root_scan();
            self.drain_events()
        } else if self.permissions_granted {
            self.handle_event(event)
        } else {
            self.queued_events.push(event);
            Rerender::No
        };

        rerender.as_bool()
    }

    fn render(&mut self, rows: usize, cols: usize) {
        let frame = self.renderer.next_frame(rows, cols, &self.matcher);
        println!("{}", frame);
    }
}

impl State {
    fn start_async_root_scan(&self) {
        self.post_repository_crawler_task(PathBuf::from("/host"), /* max_depth */ 5)
    }

    fn post_repository_crawler_task(&self, root: PathBuf, max_depth: usize) {
        // TODO: add a compile-time toggle to use one approach or the other.
        // For now, we're just running them both. They do the exact same thing, but all results are
        // stored in a set which handles duplicates for us.

        // Scan the host folder with the async `scan_host_folder` API (workaround). This API posts
        // its results back to the plugin using the `Event::FileSystemUpdate` event (see
        // `State::handle_event(…)`).
        // NOTE: This API  is a stop-gap method that allows plugins to scan a folder on the /host
        // filesystem and get back a list of files. This is a workaround for the Zellij WASI
        // runtime being extremely slow. This API might be removed in the future.
        scan_host_folder(&root);

        // Scan the host folder using the FS worker (preferred).
        // This API posts its results back to the plugin using the `Event::CustomMessage` event
        // with a `FileSystemWorkerMessage::Crawl` message.
        // NOTE: The `PluginMessage::new_to_worker(…)`'s `worker_name` argument must match the
        // worker's namespace specified when registering the worker: to send messages to the worker
        // declared with `test_worker` namespace, pass `"test"` to `::new_to_worker(…)`.
        post_message_to(PluginMessage::new_to_worker(
            "file_system", // Post to the `file_system_worker` namespace.
            &serialize(&FileSystemWorkerMessage::Crawl).unwrap(),
            &serialize(&RepositoryCrawlerRequest { root, max_depth }).unwrap(),
        ));
    }

    fn drain_events(&mut self) -> Rerender {
        if self.queued_events.is_empty() {
            return Rerender::No;
        }
        eprintln!("Draining {} events", self.queued_events.len());
        let queued_events = std::mem::take(&mut self.queued_events);
        queued_events
            .into_iter()
            .map(|event| self.handle_event(event))
            .fold(Rerender::No, std::ops::BitOr::bitor)
    }

    fn handle_event(&mut self, event: Event) -> Rerender {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                unreachable!("Already handled in `update(event)`");
            }
            Event::PermissionRequestResult(PermissionStatus::Denied) => {
                self.permissions_granted = false;
                close_self();
                Rerender::No
            }
            Event::CustomMessage(message, payload) => match deserialize(&message) {
                Ok(FileSystemWorkerMessage::Crawl) => {
                    let Ok(RepositoryCrawlerResponse { repository }) = deserialize(&payload) else {
                        return Rerender::No;
                    };
                    self.matcher.add_choice(repository);
                    Rerender::Yes
                }
                _ => Rerender::No,
            },
            Event::FileSystemUpdate(paths) => {
                let has_dot_git_dir = paths.iter().any(|(path, metadata)| {
                    path.file_name()
                        .map(|fname| fname.to_str() == Some(".git"))
                        .unwrap_or(false)
                        && metadata.map(|m| m.is_dir).unwrap_or(false)
                });
                if has_dot_git_dir {
                    let parent = paths.first().unwrap().0.parent().unwrap().to_path_buf();
                    let parent = parent
                        .strip_prefix(PathBuf::from("/host"))
                        .unwrap()
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
                has_dot_git_dir.into()
            }
            Event::SessionUpdate(sessions, _) => {
                self.all_sessions_name = sessions
                    .iter()
                    .map(|session| {
                        // TODO: There's a lot going on in this `::map(…)`, and a lot of
                        // allocations. Can we do better?
                        if session.is_current_session {
                            self.current_session_name = Some(session.name.clone());
                        }
                        session.name.clone()
                    })
                    .collect();
                Rerender::No
            }
            Event::Key(Key::Up) => self.renderer.select_up(&self.matcher),
            Event::Key(Key::Down) => self.renderer.select_down(&self.matcher),
            Event::Key(Key::Ctrl('c')) => self.terminate(),
            Event::Key(Key::Esc) => self.matcher.clear_user_input().or_else(|| self.terminate()),
            Event::Key(Key::Backspace) => self.matcher.remove_trailing_char(),
            Event::Key(Key::Char('\n')) => self.submit(),
            Event::Key(Key::Char(ch)) => {
                // NOTE: use the non-short-circuiting variant of the OR operator to force
                // evaluation of the rhs.
                self.matcher.on_user_input(ch) | self.renderer.on_user_input(&self.matcher)
            }
            _ => Rerender::No,
        }
    }

    fn terminate(&self) -> Rerender {
        close_self();
        Rerender::No
    }

    fn submit(&mut self) -> Rerender {
        self.matcher
            .matches
            .get(self.renderer.get_selected_index())
            .and_then(|m| self.safe_switch_session(PathBuf::from(&m.entry)).ok())
            .unwrap_or(Rerender::No)
    }

    fn safe_switch_session(&self, relative_cwd: PathBuf) -> Result<Rerender> {
        let session_name = hash::get_session_name(&relative_cwd)?;

        // We have to wait for the `Event::SessionUpdate` event to get the list of existing
        // sessions as well as the name of the current session.
        // TODO: queue up the "switch session" action if the current session name is still unknown
        // at this point. Realistically, we should have received a `SessionUpdate` event before our
        // crawler yields any result.
        let current_session_name = self.current_session_name.as_ref().ok_or_else(|| {
            anyhow!("internal error: failed to switch session: unknown current session name")
        })?;

        if *current_session_name == session_name {
            eprintln!("already on target session: {session_name}");
            return Ok(Rerender::No);
        }

        let cwd = self
            .config
            .root
            .as_ref()
            .ok_or_else(|| anyhow!("No repositories root directory specified"))?
            .join(relative_cwd);
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

        close_self();
        Ok(Rerender::Yes)
    }
}

mod hash;
mod matcher;
mod model;
mod protocol;
mod ui;
mod workers;

use matcher::RepositoryMatcher;
use protocol::{deserialize, serialize, Config, PipeCommand, SwitchStrategy};
use ui::Renderer;
use workers::protocol::{
    FileSystemWorkerMessage, RepositoryCrawlerRequest, RepositoryCrawlerResponse,
};
use zellij_tile::prelude::*;

use std::{
    collections::{BTreeMap, BTreeSet},
    path::PathBuf,
};
use workers::crawlers::FileSystemWorker;

#[derive(Default)]
struct State {
    config: Config,
    /// Events queued until `PermissionType::RunCommands` is provided.
    queued_events: Vec<Event>,
    /// Commands queued until the current session's name is known.
    queued_pipe_messages: Vec<PipeMessage>,
    permissions_granted: bool,
    current_session_name: Option<String>,
    all_sessions_name: BTreeSet<String>,
    last_command: PipeCommand,

    /// Cached styles.
    matcher: RepositoryMatcher,
    renderer: Renderer,
}

register_plugin!(State);
register_worker!(FileSystemWorker, file_system_worker, FILE_SYSTEM_WORKER);

impl ZellijPlugin for State {
    /// Plugin entry point.
    ///
    /// Called by Zellij when the plugin is loaded into a session.
    /// Requests the required permissions and install asynchronous handlers to deal with requests
    /// responses.
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
        self.config.switch_startegy = match configuration.get("strategy").map(|s| s.as_str()) {
            Some("replace") => SwitchStrategy::Replace,
            Some("create-new") => SwitchStrategy::CreateNew,
            _ => SwitchStrategy::Unknown,
        };

        if self.permissions_granted {
            // Start scanning immediatelly since permissions have already been granted.
            self.start_async_root_scan();

            // Hide the plugin window. It's just meant to be running in the background and
            // listening to [SwitchSession] requests sent via its pipe.
            hide_self();
        }
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        eprintln!("pipe_message: {:?}", pipe_message);
        if self.current_session_name.is_some() {
            self.handle_pipe_message(&pipe_message)
        } else {
            self.queued_pipe_messages.push(pipe_message);
            false
        }
    }

    fn update(&mut self, event: Event) -> bool {
        if let Event::PermissionRequestResult(PermissionStatus::Granted) = event {
            self.permissions_granted = true;
            self.start_async_root_scan();
            return self.drain_events();
        }
        if self.permissions_granted {
            self.handle_event(&event)
        } else {
            self.queued_events.push(event);
            false
        }
    }

    fn render(&mut self, rows: usize, cols: usize) {
        let frame = self.renderer.next_frame(rows, cols, &self.matcher);
        println!("{}", frame);
        //println!("");
        //println!(
        //    "Permissions have been granted: {}",
        //    color_bool(self.permissions_granted)
        //);
        //println!("");
        //println!(
        //    "Current session name: {}",
        //    color_bold(
        //        CYAN,
        //        &(self.current_session_name.clone()).unwrap_or("Unkown".to_string())
        //    )
        //);
        //println!("");
        //println!("Last command: {:?}", self.last_command);
    }
}

impl State {
    fn start_async_root_scan(&self) {
        self.post_repository_crawler_task(PathBuf::from("/host"), /* max_depth */ 5)
    }

    fn post_repository_crawler_task(&self, root: PathBuf, max_depth: usize) {
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

    fn drain_events(&mut self) -> bool {
        if self.queued_events.is_empty() {
            return false;
        }
        eprintln!("Draining {} events", self.queued_events.len());
        self.queued_events
            .drain(..)
            .collect::<Vec<_>>()
            .iter()
            .map(|event| self.handle_event(event))
            .fold(false, |render, result| render | result)
    }

    fn handle_event(&mut self, event: &Event) -> bool {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                unreachable!("Already handled in `update(event)`");
            }
            Event::PermissionRequestResult(PermissionStatus::Denied) => {
                self.permissions_granted = false;
                close_self();
                false
            }
            Event::CustomMessage(message, payload) => match deserialize(&message) {
                Ok(FileSystemWorkerMessage::Crawl) => {
                    if let Ok(RepositoryCrawlerResponse { repository }) = deserialize(&payload) {
                        self.matcher.add_choice(repository);
                        true
                    } else {
                        false
                    }
                }
                _ => false,
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
                    for dir in paths.iter().filter_map(|(path, metadata)| {
                        metadata
                            .map(|m| if m.is_dir { Some(path) } else { None })
                            .unwrap_or_default()
                    }) {
                        scan_host_folder(dir);
                    }
                }
                has_dot_git_dir
            }
            Event::SessionUpdate(sessions, _) => {
                self.all_sessions_name = sessions
                    .iter()
                    .map(|session| {
                        if session.is_current_session {
                            self.current_session_name = Some(session.name.clone());
                        }
                        session.name.clone()
                    })
                    .collect();

                // Drain messages that were queued while the session name was unknown.
                // NOTE: checking `self.current_session_name.is_some()` should always be
                // true at this point, but prevents crashes in case of unexpected
                // application state.
                self.current_session_name.is_some() && self.drain_pipe_messages()
            }
            Event::Key(Key::Up) => self.renderer.select_up(&self.matcher),
            Event::Key(Key::Down) => self.renderer.select_down(&self.matcher),
            Event::Key(Key::Ctrl('c')) => self.terminate(),
            Event::Key(Key::Esc) => self.matcher.clear_user_input() || self.terminate(),
            Event::Key(Key::Backspace) => self.matcher.pop_char(),
            Event::Key(Key::Char('\n')) => self.submit(),
            Event::Key(Key::Char(ch)) => {
                // NOTE: use the non-short-circuiting variant of the OR operator to force
                // evaluation of the rhs.
                self.matcher.on_user_input(*ch) | self.renderer.on_user_input(&self.matcher)
            }
            _ => false,
        }
    }

    fn terminate(&self) -> bool {
        close_self();
        false
    }

    fn submit(&mut self) -> bool {
        self.matcher
            .matches
            .get(self.renderer.get_selected_index())
            .and_then(|m| self.safe_switch_session(PathBuf::from(&m.entry)).ok())
            .unwrap_or(false)
    }

    fn drain_pipe_messages(&mut self) -> bool {
        if self.queued_pipe_messages.is_empty() {
            return false;
        }
        eprintln!("Draining {} pipe messages", self.queued_pipe_messages.len());
        self.queued_pipe_messages
            .drain(..)
            .collect::<Vec<_>>()
            .iter()
            .map(|pipe_message| self.handle_pipe_message(pipe_message))
            .fold(false, |render, result| render | result)
    }

    fn handle_pipe_message(&mut self, pipe_message: &PipeMessage) -> bool {
        if let Some(payload) = &pipe_message.payload {
            let mut partition = payload.splitn(2, " ");
            self.last_command = match partition.next() {
                Some(command) => match command {
                    "Exec" => {
                        if let Some(path) = partition.next() {
                            PipeCommand::Exec(PathBuf::from(path))
                        } else {
                            eprintln!("missing `Exec` command argument");
                            return false;
                        }
                    }
                    "SwitchSession" => {
                        if let Some(args) = partition.next() {
                            let mut argv = args.splitn(2, " ");
                            if let (Some(session_name), Some(cwd)) = (argv.next(), argv.next()) {
                                PipeCommand::SwitchSession(session_name.into(), PathBuf::from(cwd))
                            } else {
                                PipeCommand::InvalidArguments(command.into(), Some(args.into()))
                            }
                        } else {
                            PipeCommand::InvalidArguments(command.into(), None)
                        }
                    }
                    _ => PipeCommand::UnknownCommand(command.into()),
                },
                None => PipeCommand::InvalidPayload(payload.into()),
            };
            eprintln!("command={:?}", self.last_command);
            return self.handle_command(self.last_command.clone());
        }
        false
    }

    fn handle_command(&self, command: PipeCommand) -> bool {
        match command {
            PipeCommand::Exec(path) => self.exec(path),
            PipeCommand::SwitchSession(session_name, path) => {
                self.switch_session(session_name, path)
            }
            PipeCommand::UnknownCommand(command) => {
                eprintln!("unknown command `{}`", command);
                show_self(true);
                false
            }
            PipeCommand::InvalidPayload(payload) => {
                eprintln!("invalid payload `{}`", payload);
                show_self(true);
                false
            }
            PipeCommand::InvalidArguments(command, args) => {
                eprintln!("invalid arguments for command `{}`: `{:?}`", command, args);
                show_self(true);
                false
            }
        }
    }

    fn exec(&self, path: PathBuf) -> bool {
        open_command_pane_floating(
            CommandToRun {
                path,
                args: vec![],
                cwd: Some(PathBuf::from("~")),
            },
            /* coordinates */ None,
        );
        true
    }

    fn switch_session(&self, session_name: String, cwd: PathBuf) -> bool {
        if let Some(current_session_name) = &self.current_session_name {
            if *current_session_name == session_name {
                eprintln!("already on target session: {}", session_name);
                return false;
            }

            // match self.config.switch_startegy {
            //     // Switch to the existing session, and leave the current one unchanged.
            //     SwitchStartegy::CreateNew => zellij_switch_session(session_name, cwd),
            //     SwitchStartegy::Replace | SwitchStartegy::Unknown => {
            //         // Switch to the existing session, and terminate the current one.
            //         zellij_switch_session(session_name, cwd);
            //         todo!("kill current session");
            //     }
            // };

            switch_session_with_layout(Some(&session_name), self.config.layout.clone(), Some(cwd));
            close_self();
            return true;
        }

        unreachable!("failed to switch session: unknown current session name")
    }

    fn safe_switch_session(&self, relative_cwd: PathBuf) -> Result<bool> {
        let session_name = hash::get_session_name(&relative_cwd)?;
        let current_session_name = self.current_session_name.as_ref().ok_or_else(|| {
            anyhow!("internal error: failed to switch session: unknown current session name")
        })?;

        if *current_session_name == session_name {
            eprintln!("already on target session: {}", session_name);
            return Ok(false);
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
        // if !self.all_sessions_name.contains(&session_name) {
        //     kill_sessions(&[current_session_name]);
        // }

        close_self();
        Ok(true)
    }
}

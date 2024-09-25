//use ansi_term::{Colour::Fixed, Style};
use zellij_tile::prelude::*;

use std::{collections::BTreeMap, path::PathBuf};

#[derive(Default)]
struct State {
    switch_startegy: SwitchStartegy,
    /// Events queued until `PermissionType::RunCommands` is provided.
    queued_events: Vec<Event>,
    /// Commands queued until the current session's name is known.
    queued_pipe_messages: Vec<PipeMessage>,
    permissions_granted: bool,
    current_session_name: Option<String>,
    all_sessions_name: Vec<String>,
    last_command: PipeCommand,
}

#[derive(Debug, Clone)]
enum SwitchStartegy {
    Unknown,
    Replace,
    CreateNew,
}

#[derive(Debug, Clone)]
enum PipeCommand {
    UnknownCommand(String),
    InvalidPayload(String),
    InvalidArguments(String, Option<String>),
    Exec(PathBuf),
    SwitchSession(String, PathBuf),
}

impl Default for SwitchStartegy {
    fn default() -> SwitchStartegy {
        SwitchStartegy::Unknown
    }
}

impl Default for PipeCommand {
    fn default() -> PipeCommand {
        PipeCommand::UnknownCommand("init".to_owned())
    }
}

register_plugin!(State);

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
        subscribe(&[EventType::PermissionRequestResult, EventType::SessionUpdate]);

        self.switch_startegy = match configuration.get("strategy").map(|s| s.as_str()) {
            Some("replace") => SwitchStartegy::Replace,
            Some("create-new") => SwitchStartegy::CreateNew,
            _ => SwitchStartegy::Unknown,
        };

        if self.permissions_granted {
            // If permission have already been granted, hide the plugin window. It's just meant to
            // be running in the background and listening to [SwitchSession] requests sent via its
            // pipe.
            hide_self();
        }
    }

    fn pipe(&mut self, pipe_message: PipeMessage) -> bool {
        eprintln!("pipe_message: {:?}", pipe_message);
        if self.current_session_name.is_some() {
            self.handle_pipe_message(&pipe_message)
        } else {
            self.queued_pipe_messages.push(pipe_message);
            true
        }
    }

    fn update(&mut self, event: Event) -> bool {
        if let Event::PermissionRequestResult(PermissionStatus::Granted) = event {
            self.permissions_granted = true;
            return self.drain_events();
        }
        if self.permissions_granted {
            self.handle_event(&event)
        } else {
            self.queued_events.push(event);
            false
        }
    }

    //fn render(&mut self, _rows: usize, _cols: usize) {
    //    println!("");
    //    println!(
    //        "Permissions have been granted: {}",
    //        color_bool(self.permissions_granted)
    //    );
    //    println!("");
    //    println!(
    //        "Current session name: {}",
    //        color_bold(
    //            CYAN,
    //            &(self.current_session_name.clone()).unwrap_or("Unkown".to_string())
    //        )
    //    );
    //    println!("");
    //    println!("Last command: {:?}", self.last_command);
    //}
}

impl State {
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

                // This check should always be true at this point, but prevents crashes in case of
                // unexpected application state.
                if self.current_session_name.is_some() {
                    // Drain [PipeMessage]s that were queued while the current session name was
                    // unknown.
                    self.drain_pipe_messages()
                } else {
                    false
                }
            }
            Event::Key(Key::Char('q')) => {
                close_self();
                false
            }
            _ => false,
        }
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
        match &self.current_session_name {
            Some(current_session_name) => {
                if *current_session_name == session_name {
                    eprintln!("already on target session: {}", session_name);
                    return false;
                }

                // NOTE: Currently, this plugin assumes that the session has been created
                // out-of-band by the calling script (namely `zellij-select-repository`).

                //match self.switch_startegy {
                //    // Switch to the existing session, and leave the current one unchanged.
                //    SwitchStartegy::CreateNew => zellij_switch_session(session_name, cwd),
                //    SwitchStartegy::Replace | SwitchStartegy::Unknown => {
                //        // Switch to the existing session, and terminate the current one.
                //        zellij_switch_session(session_name, cwd);
                //        todo!("kill current session");
                //    }
                //};
                zellij_switch_session(session_name, cwd);
                close_self();
                true
            }
            None => unreachable!("failed to switch session: unknown current session name"),
        }
    }
}

fn zellij_switch_session(name: String, cwd: PathBuf) {
    let layout: LayoutInfo = LayoutInfo::File("default".to_string());
    switch_session_with_layout(Some(&name), layout, Some(cwd));
}

pub const CYAN: u8 = 6;
pub const RED: u8 = 1;
pub const GREEN: u8 = 2;

//fn color_bold(color: u8, text: &str) -> String {
//    Style::new().fg(Fixed(color)).bold().paint(text).to_string()
//}
//
//fn color_bool(value: bool) -> String {
//    Style::new()
//        .fg(Fixed(if value { GREEN } else { RED }))
//        .bold()
//        .paint(value.to_string())
//        .to_string()
//}

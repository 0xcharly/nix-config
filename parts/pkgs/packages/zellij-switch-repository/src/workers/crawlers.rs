use crate::{
    protocol::{deserialize, serialize},
    workers::protocol::{FileSystemWorkerMessage, RepositoryCrawlerResponse},
};

use super::fs::list_repositories;
use super::protocol::RepositoryCrawlerRequest;

use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use zellij_tile::prelude::*;

#[derive(Default, Deserialize, Serialize)]
pub(crate) struct FileSystemWorker {}

impl FileSystemWorker {
    fn crawl(&mut self, root: &PathBuf, max_depth: usize) {
        // NOTE: This is a little silly as we already have the full list of path yet choose to send
        // them back to the plugin one by one. However, this is "by design" and "temporary", and
        // the `list_repositories(…)` function will be updated to return an iterator instead.
        for repository in list_repositories(root, max_depth) {
            // TODO: report errors to the user through the UI.
            post_message_to_plugin(PluginMessage::new_to_plugin(
                &serialize(&FileSystemWorkerMessage::Crawl).unwrap(),
                &serialize(&RepositoryCrawlerResponse { repository }).unwrap(),
            ));
        }
    }
}

impl<'de> ZellijWorker<'de> for FileSystemWorker {
    fn on_message(&mut self, message: String, payload: String) {
        let message = deserialize::<FileSystemWorkerMessage>(&message);
        let payload = deserialize::<RepositoryCrawlerRequest>(&payload);

        // NOTE: This syntax is currently unstable: https://github.com/rust-lang/rust/issues/53667.
        // if let Ok(FileSystemWorkerMessage::Crawl) = message && let Ok(request) = payload { … }

        match (message, payload) {
            (Ok(FileSystemWorkerMessage::Crawl), Ok(request)) => {
                self.crawl(&request.root, request.max_depth);
            }
            _ => (),
        }
    }
}

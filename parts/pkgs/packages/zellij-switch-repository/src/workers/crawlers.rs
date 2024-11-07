use crate::{
    marshall_plugin::{deserialize, serialize},
    workers::protocol::{FileSystemWorkerMessage, RepositoryCrawlerResponse},
};

use super::fs::list_repositories;
use super::protocol::RepositoryCrawlerRequest;

use anyhow;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use zellij_tile::prelude::*;

type Result = anyhow::Result<()>;

#[derive(Default, Deserialize, Serialize)]
pub(crate) struct FileSystemWorker {}

impl FileSystemWorker {
    fn parse_request(&mut self, message: String, payload: String) -> Result {
        let message = deserialize::<FileSystemWorkerMessage>(&message)
            .with_context(|| "deserializing inbound message from plugin")?;
        assert!(
            matches!(message, FileSystemWorkerMessage::Crawl),
            "unsupported worker message"
        );

        let request = deserialize::<RepositoryCrawlerRequest>(&payload)
            .with_context(|| "deserializing inbound payload from plugin")?;

        self.crawl(&request.root, request.max_depth)
    }

    fn crawl(&mut self, root: &PathBuf, max_depth: usize) -> Result {
        let message = serialize(&FileSystemWorkerMessage::Crawl)?;

        // NOTE: This is a little silly as we already have the full list of path yet choose to send
        // them back to the plugin one by one. However, this is "by design" and "temporary", and
        // the `list_repositories(…)` function will be updated to return an iterator instead.
        for repository in list_repositories(root, max_depth) {
            post_message_to_plugin(PluginMessage::new_to_plugin(
                &message,
                &serialize(&RepositoryCrawlerResponse { repository })?,
            ));
        }

        Ok(())
    }
}

impl<'de> ZellijWorker<'de> for FileSystemWorker {
    fn on_message(&mut self, message: String, payload: String) {
        if let Err(error) = self.parse_request(message, payload) {
            // NOTE: if we failed to serialize our response, chances are we're not going to be able
            // to send the error back to the plugin. Fallback to logging the error.
            eprintln!("failed to scan host: {error:?}");
        }
    }
}

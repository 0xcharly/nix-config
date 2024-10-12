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
pub struct FileSystemWorker {}

impl FileSystemWorker {
    fn crawl(&mut self, root: &PathBuf, max_depth: usize) {
        for repository in list_repositories(root, max_depth) {
            post_message_to_plugin(PluginMessage::new_to_plugin(
                &serialize(&FileSystemWorkerMessage::Crawl).unwrap(),
                &serialize(&RepositoryCrawlerResponse { repository }).unwrap(),
            ));
        }
    }
}

impl<'de> ZellijWorker<'de> for FileSystemWorker {
    fn on_message(&mut self, message: String, payload: String) {
        match deserialize::<FileSystemWorkerMessage>(&message) {
            Ok(FileSystemWorkerMessage::Crawl) => {
                if let Ok(request) = deserialize::<RepositoryCrawlerRequest>(&payload) {
                    self.crawl(&request.root, request.max_depth);
                }
            }
            _ => (),
        }
    }
}

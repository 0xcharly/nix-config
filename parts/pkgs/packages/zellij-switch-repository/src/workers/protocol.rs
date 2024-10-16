use std::path::PathBuf;

use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub(crate) enum FileSystemWorkerMessage {
    Crawl,
}

/// Request associated with a `FileSystemWorkerMessage::Crawl`.
#[derive(Serialize, Deserialize)]
pub(crate) struct RepositoryCrawlerRequest {
    pub root: PathBuf,
    pub max_depth: usize,
}

/// Response from a worker to a `FileSystemWorkerMessage::Crawl`.
#[derive(Serialize, Deserialize)]
pub(crate) struct RepositoryCrawlerResponse {
    pub repository: PathBuf,
}

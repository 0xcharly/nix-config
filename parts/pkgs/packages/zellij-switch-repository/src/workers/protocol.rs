use std::path::PathBuf;

use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub enum FileSystemWorkerMessage {
    Crawl,
}

/// Request associated with a `FileSystemWorkerMessage::Crawl`.
#[derive(Serialize, Deserialize)]
pub struct RepositoryCrawlerRequest {
    pub root: PathBuf,
    pub max_depth: usize,
}

/// Response from a worker to a `FileSystemWorkerMessage::Crawl`.
#[derive(Serialize, Deserialize)]
pub struct RepositoryCrawlerResponse {
    pub repository: PathBuf,
}

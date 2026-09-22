use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Serialize, Deserialize, Clone, Default)]
pub struct Session {
    pub access_token: String,
    pub refresh_token: String,
    pub username: String,
}

#[derive(Serialize, Deserialize, Clone, Default)]
pub struct SplitTunnelConfig {
    pub apps: Vec<String>,
    pub destinations: Vec<String>,
}

#[derive(Serialize, Deserialize, Clone, Default)]
pub struct AppData {
    pub session: Option<Session>,
    pub split_tunnel: SplitTunnelConfig,
}

fn config_path() -> PathBuf {
    let mut dir = dirs::config_dir().unwrap_or(std::env::temp_dir());
    dir.push("TayyemVPN");
    fs::create_dir_all(&dir).ok();
    dir.push("settings.json");
    dir
}

pub fn load() -> AppData {
    let path = config_path();
    match fs::read_to_string(&path) {
        Ok(contents) => serde_json::from_str(&contents).unwrap_or_default(),
        Err(_) => AppData::default(),
    }
}

pub fn save(data: &AppData) {
    let path = config_path();
    if let Ok(json) = serde_json::to_string_pretty(data) {
        let _ = fs::write(path, json);
    }
}

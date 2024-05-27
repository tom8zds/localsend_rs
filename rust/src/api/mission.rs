use std::{collections::HashMap, sync::Arc};

use log::debug;
use tokio::sync::{watch, Mutex};

use super::model::{FileInfo, Mission, MissionState};

impl Mission {
    pub fn get_file_info(&self, token: &str) -> Option<FileInfo> {
        if !self.token_map.contains_key(token) {
            debug!("token not found");
            return None;
        }
        let file_id = self.token_map.get(token).unwrap();
        if !self.info_map.contains_key(file_id) {
            debug!("file id not found");
            return None;
        }
        Some(self.info_map.get(file_id).unwrap().clone())
    }
}

lazy_static::lazy_static! {
    static ref MISSION_MAP: Arc<Mutex<HashMap<String, Mission>>> =
        Arc::new(Mutex::new(HashMap::new()));
    static ref MISSON_CHANNEL: (watch::Sender<HashMap<String, Mission>>, watch::Receiver<HashMap<String, Mission>>) = watch::channel(HashMap::new());
}

pub fn get_mission_listener() -> watch::Receiver<HashMap<String, Mission>> {
    MISSON_CHANNEL.1.clone()
}

pub async fn clear_missions() {
    let mut mission_map = MISSION_MAP.lock().await;
    mission_map.clear();
    let _ = MISSON_CHANNEL.0.send(mission_map.clone());
}

pub async fn create_mission(
    info_map: HashMap<String, FileInfo>,
) -> (String, HashMap<String, String>) {
    let id = uuid::Uuid::new_v4().to_string();
    let mut token_map = HashMap::new();
    let mut reverse_token_map = HashMap::new();
    info_map.iter().for_each(|(key, value)| {
        let token = uuid::Uuid::new_v4().to_string();
        token_map.insert(key.clone(), token.clone());
        reverse_token_map.insert(token.clone(), key.clone());
    });
    let mission = Mission {
        id: id.clone(),
        state: MissionState::Accepting,
        token_map: reverse_token_map,
        info_map: info_map.clone(),
        accepted: vec![],
    };
    add_mission(mission).await;
    (id, token_map)
}

pub async fn add_mission(mission: Mission) {
    let mut mission_map = MISSION_MAP.lock().await;
    mission_map.insert(mission.id.clone(), mission);
    let _ = MISSON_CHANNEL.0.send(mission_map.clone());
}

pub async fn remove_mission(id: &str) {
    let mut mission_map = MISSION_MAP.lock().await;
    mission_map.remove(id);
    let _ = MISSON_CHANNEL.0.send(mission_map.clone());
}

pub async fn accept_mission(id: &str) {
    update_mission_state(id, MissionState::Accepted).await;
}

pub async fn reject_mission(id: &str) {
    update_mission_state(id, MissionState::Rejected).await;
}

pub async fn update_file_state(id: &str, file_name: String) {
    let mut mission_map = MISSION_MAP.lock().await;
    if !mission_map.contains_key(id) {
        return;
    }
    let mission = mission_map.get_mut(id).unwrap();
    if mission.accepted.contains(&file_name) {
        panic!("file already accepted");
    } else {
        mission.accepted.push(file_name);
    }

    if mission.accepted.len() == mission.info_map.len() {
        mission.state = MissionState::Finished;
        let _ = MISSON_CHANNEL.0.send(mission_map.clone());
    }
}

pub async fn update_mission_state(id: &str, state: MissionState) {
    let mut mission_map = MISSION_MAP.lock().await;
    if !mission_map.contains_key(id) {
        return;
    }
    let mut mission = mission_map.get_mut(id).unwrap();
    mission.state = state;
    let _ = MISSON_CHANNEL.0.send(mission_map.clone());
}

pub async fn get_mission(id: &str) -> Option<Mission> {
    let mission_map = MISSION_MAP.lock().await;
    if !mission_map.contains_key(id) {
        return None;
    }
    Some(mission_map.get(id).unwrap().clone())
}

pub async fn get_missions() -> HashMap<String, Mission> {
    let mission_map = MISSION_MAP.lock().await;
    mission_map.clone()
}

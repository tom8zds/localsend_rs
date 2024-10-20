use std::collections::HashMap;

use serde_derive::{Deserialize, Serialize};

use crate::api::model::{FileInfo, SenderInfo};

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NodeDevice {
    pub alias: String,
    pub version: String,
    pub device_model: String,
    pub device_type: String,
    pub fingerprint: String,
    pub address: String,
    pub port: u16,
    pub protocol: String,
    pub download: bool,
    pub announcement: bool,
    pub announce: bool,
}

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NodeAnnounce {
    pub alias: String,
    pub version: String,
    pub device_model: String,
    pub device_type: String,
    pub fingerprint: String,
    pub port: u16,
    pub protocol: String,
    pub download: bool,
    pub announcement: bool,
    pub announce: bool,
}

impl NodeDevice {
    pub fn from_announce(announce: &NodeAnnounce, address: &str) -> NodeDevice {
        NodeDevice {
            alias: announce.alias.clone(),
            version: announce.version.clone(),
            device_model: announce.device_model.clone(),
            device_type: announce.device_type.clone(),
            fingerprint: announce.fingerprint.clone(),
            address: address.to_string(),
            port: announce.port,
            protocol: announce.protocol.clone(),
            download: announce.download,
            announcement: announce.announcement,
            announce: announce.announce,
        }
    }

    pub fn to_sender(&self) -> SenderInfo {
        SenderInfo {
            alias: self.alias.clone(),
            version: self.version.clone(),
            device_model: self.device_model.clone(),
            device_type: self.device_type.clone(),
            fingerprint: self.fingerprint.clone(),
            port: self.port,
            protocol: self.protocol.clone(),
            download: self.download,
        }
    }

    pub fn to_announce(&self) -> NodeAnnounce {
        NodeAnnounce {
            alias: self.alias.clone(),
            version: self.version.clone(),
            device_model: self.device_model.clone(),
            device_type: self.device_type.clone(),
            fingerprint: self.fingerprint.clone(),
            port: self.port,
            protocol: self.protocol.clone(),
            download: self.download,
            announcement: self.announcement,
            announce: self.announce,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Mission {
    pub id: String,
    pub sender: NodeDevice,
    pub id_token_map: HashMap<String, String>,
    pub token_id_map: HashMap<String, String>,
    pub info_map: HashMap<String, FileInfo>,
}

impl Mission {
    pub fn new(info_map: HashMap<String, FileInfo>, sender: NodeDevice) -> Self {
        let id = uuid::Uuid::new_v4().to_string();
        let mut id_token_map = HashMap::new();
        let mut token_id_map = HashMap::new();
        info_map.iter().for_each(|(id, _value)| {
            let token = uuid::Uuid::new_v4().to_string();
            id_token_map.insert(id.clone(), token.clone());
            token_id_map.insert(token.clone(), id.clone());
        });

        Mission {
            id: id.clone(),
            sender,
            id_token_map,
            token_id_map,
            info_map: info_map.clone(),
        }
    }
}

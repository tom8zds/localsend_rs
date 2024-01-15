use serde_derive::{Serialize, Deserialize};

#[derive(Default, Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Node {
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

impl Node {
    pub fn from_announce(announce: &NodeAnnounce, address: &str) -> Node {
        Node {
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


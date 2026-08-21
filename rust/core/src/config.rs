/// Runtime configuration for a [`crate::CoreHandle`].
///
/// NOTE: the field set and order are part of the Flutter Rust Bridge
/// boundary (the ffi crate mirrors this struct); do not add or remove
/// fields without regenerating the FRB bindings.
#[derive(Clone, Debug)]
pub struct CoreConfig {
    pub port: u16,
    pub interface_addr: String,
    pub multicast_addr: String,
    pub multicast_port: u16,
    pub store_path: String,
}

impl Default for CoreConfig {
    fn default() -> Self {
        CoreConfig {
            port: 53317,
            interface_addr: "0.0.0.0".to_string(),
            multicast_addr: "224.0.0.167".to_string(),
            multicast_port: 53317,
            store_path: "./".to_string(),
        }
    }
}

//! FRB boundary type mirror of `localsend_core::CoreConfig`.
//!
//! The FRB codegen implements foreign traits (`IntoDart`, ...) for
//! these types, so they must stay defined in this crate (orphan rule);
//! `bridge.rs` converts to/from the core types.

#[derive(Clone)]
pub struct CoreConfig {
    pub port: u16,
    pub interface_addr: String,
    pub multicast_addr: String,
    pub multicast_port: u16,
    pub store_path: String,
}

impl CoreConfig {
    pub fn to_core(&self) -> localsend_core::CoreConfig {
        localsend_core::CoreConfig {
            port: self.port,
            interface_addr: self.interface_addr.clone(),
            multicast_addr: self.multicast_addr.clone(),
            multicast_port: self.multicast_port,
            store_path: self.store_path.clone(),
        }
    }
}

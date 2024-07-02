pub mod pending;
pub mod transfer;

#[derive(Clone)]
pub struct MissionHandle {
    pub pending: pending::Handle,
    pub transfer: transfer::Handle,
}

impl MissionHandle {
    pub fn new() -> Self {
        let transfer = transfer::Handle::new();
        let pending = pending::Handle::new(transfer.clone());

        Self { pending, transfer }
    }
}

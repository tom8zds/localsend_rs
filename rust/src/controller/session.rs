use tokio::io::AsyncRead;

use crate::{
    api::model::{FileRequest, UploadTask},
    service::session::SessionService,
};

struct SessionController {
    session_service: Box<dyn SessionService>,
}

impl SessionController {
    fn new(session_service: Box<dyn SessionService>) -> Self {
        SessionController { session_service }
    }

    async fn prepare_upload(request: FileRequest) {}

    async fn handle_upload<'a, R>(task: UploadTask, reader: &'a mut R)
    where
        R: AsyncRead + Unpin + ?Sized,
    {
    }
}

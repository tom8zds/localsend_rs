use std::io::Result;
use std::pin::Pin;
use std::task::{Context, Poll};
use std::time::Duration;

use pin_project_lite::pin_project;
use tokio::io::AsyncWrite;
use tokio::sync::watch::Sender;
use tokio::time::{interval, Interval};

pin_project! {
    /// AsyncWrite adapter reporting total bytes written through a watch
    /// channel, at most every 100ms.
    pub struct ProgressWriteAdapter<R: AsyncWrite> {
        #[pin]
        inner: R,
        interval: Interval,
        interval_bytes: usize,
        tx: Sender<usize>
    }
}

impl<R: AsyncWrite> ProgressWriteAdapter<R> {
    pub fn new(inner: R, tx: Sender<usize>) -> Self {
        Self {
            inner,
            interval: interval(Duration::from_millis(100)),
            interval_bytes: 0,
            tx,
        }
    }
}

impl<R: AsyncWrite> AsyncWrite for ProgressWriteAdapter<R> {
    fn poll_write(self: Pin<&mut Self>, cx: &mut Context<'_>, buf: &[u8]) -> Poll<Result<usize>> {
        let this = self.project();

        let result = this.inner.poll_write(cx, buf);
        if let Poll::Ready(Ok(written)) = &result {
            *this.interval_bytes += written;
        }

        if this.interval.poll_tick(cx).is_ready() {
            let _ = this.tx.send(*this.interval_bytes);
        }

        result
    }

    fn poll_flush(self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Result<()>> {
        self.project().inner.poll_flush(cx)
    }

    fn poll_shutdown(
        self: Pin<&mut Self>,
        cx: &mut Context<'_>,
    ) -> Poll<std::result::Result<(), std::io::Error>> {
        self.project().inner.poll_shutdown(cx)
    }
}

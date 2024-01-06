use std::io::Result;
use std::pin::Pin;
use std::task::{Context, Poll};
use std::time::Duration;
use tokio::sync::mpsc;

use pin_project::pin_project;
use tokio::io::{AsyncRead, ReadBuf};
use tokio::time::{interval, Interval};

use super::model::Progress;

#[pin_project]
pub struct ProgressReadAdapter<R: AsyncRead> {
    #[pin]
    inner: R,
    interval: Interval,
    interval_bytes: usize,
    total_bytes: usize,
    tx: mpsc::Sender<Progress>,
}

impl<R: AsyncRead> ProgressReadAdapter<R> {
    pub fn new(inner: R, total_bytes: usize, progress: mpsc::Sender<Progress>) -> Self {
        Self {
            inner,
            interval: interval(Duration::from_millis(100)),
            interval_bytes: 0,
            total_bytes,
            tx: progress,
        }
    }
}

impl<R: AsyncRead> AsyncRead for ProgressReadAdapter<R> {
    fn poll_read(
        self: Pin<&mut Self>,
        cx: &mut Context<'_>,
        buf: &mut ReadBuf<'_>,
    ) -> Poll<Result<()>> {
        let this = self.project();

        let before = buf.filled().len();
        let result = this.inner.poll_read(cx, buf);
        let after = buf.filled().len();

        let tx = this.tx.clone();

        *this.interval_bytes += after - before;
        match this.interval.poll_tick(cx) {
            Poll::Pending => {}
            Poll::Ready(_) => {
                let progress = *this.interval_bytes * 100 / *this.total_bytes;

                println!(
                    "progress: {}, current: {}, total: {}",
                    progress, *this.interval_bytes, *this.total_bytes
                );
                let _ = tx.try_send(Progress::Progress(*this.interval_bytes, *this.total_bytes));
            }
        };

        result
    }
}

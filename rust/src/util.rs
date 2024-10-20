use std::io::{Read, Result};
use std::pin::Pin;
use std::task::{Context, Poll};
use std::time::Duration;

use pin_project_lite::pin_project;
use tokio::io::{AsyncRead, AsyncWrite, ReadBuf};
use tokio::sync::watch::Sender;
use tokio::time::{interval, Interval};

use crate::session::progress::Progress;

pin_project! {
    pub struct ProgressWriteAdapter<R: AsyncWrite> {
        #[pin]
        inner: R,
        interval: Interval,
        interval_bytes: usize,
        total_size: usize,
        tx: Sender<Progress>
    }
}

impl<R: AsyncWrite> ProgressWriteAdapter<R> {
    pub fn new(inner: R, total_size: usize, tx: Sender<Progress>) -> Self {
        Self {
            inner,
            interval: interval(Duration::from_millis(100)),
            total_size,
            interval_bytes: 0,
            tx,
        }
    }
}

impl<R: AsyncWrite> AsyncWrite for ProgressWriteAdapter<R> {
    fn poll_write(self: Pin<&mut Self>, cx: &mut Context<'_>, buf: &[u8]) -> Poll<Result<usize>> {
        let this = self.project();

        let result = this.inner.poll_write(cx, buf);
        match result {
            Poll::Ready(ref res) => {
                if res.is_ok() {
                    *this.interval_bytes = *this.interval_bytes + res.as_ref().clone().unwrap();
                }
            }
            _ => {}
        }

        match this.interval.poll_tick(cx) {
            Poll::Pending => {}
            Poll::Ready(_) => {
                let _ = this.tx.send(Progress {
                    progress: *this.interval_bytes,
                    total: this.total_size.clone(),
                });
            }
        };

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

pin_project! {
    pub struct ProgressReadAdapter<R: Read> {
        #[pin]
        inner: R,
        interval: Interval,
        interval_bytes: usize,
        tx: Sender<usize>
    }
}

impl<R: Read> ProgressReadAdapter<R> {
    pub fn new(inner: R, tx: Sender<usize>) -> Self {
        Self {
            inner,
            interval: interval(Duration::from_millis(100)),
            interval_bytes: 0,
            tx,
        }
    }
}

impl<R: Read> Read for ProgressReadAdapter<R> {
    fn read(&mut self, buf: &mut [u8]) -> Result<usize> {
        let result = self.inner.read(buf);
        match result {
            Ok(n) => {
                self.interval_bytes += n;
            }
            Err(_) => {}
        }

        let _ = self.tx.send(self.interval_bytes);

        result
    }
}

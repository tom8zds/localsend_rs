//! Panel sqlite: minute-granular metrics (30-day retention) and the
//! credential-issuance audit log (suffix/ttl/time only, never
//! credential values).

use rusqlite::Connection;
use std::path::Path;
use std::sync::Mutex;

pub struct Store {
    conn: Mutex<Connection>,
}

impl Store {
    pub fn open(path: &Path) -> rusqlite::Result<Self> {
        let conn = Connection::open(path)?;
        conn.execute_batch(
            "CREATE TABLE IF NOT EXISTS metrics (
                 ts INTEGER NOT NULL,          -- unix minutes
                 allocations_udp INTEGER NOT NULL,
                 allocations_tcp INTEGER NOT NULL,
                 traffic_rcvd INTEGER NOT NULL,  -- cumulative bytes
                 traffic_sent INTEGER NOT NULL
             );
             CREATE INDEX IF NOT EXISTS metrics_ts ON metrics(ts);
             CREATE TABLE IF NOT EXISTS issuances (
                 ts INTEGER NOT NULL,
                 suffix TEXT NOT NULL,
                 ttl INTEGER NOT NULL
             );",
        )?;
        Ok(Store {
            conn: Mutex::new(conn),
        })
    }

    pub fn record_metrics(
        &self,
        ts_min: i64,
        alloc_udp: i64,
        alloc_tcp: i64,
        rcvd: i64,
        sent: i64,
    ) {
        let _ = self.conn.lock().unwrap().execute(
            "INSERT OR REPLACE INTO metrics (ts, allocations_udp, allocations_tcp, traffic_rcvd, traffic_sent)
             VALUES (?1, ?2, ?3, ?4, ?5)",
            rusqlite::params![ts_min, alloc_udp, alloc_tcp, rcvd, sent],
        );
        // retention: 30 days of minute rows
        let cutoff = ts_min - 30 * 24 * 60;
        let _ = self.conn.lock().unwrap().execute(
            "DELETE FROM metrics WHERE ts < ?1",
            rusqlite::params![cutoff],
        );
    }

    pub fn record_issue(&self, suffix: &str, ttl: u64) {
        let ts = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;
        let _ = self.conn.lock().unwrap().execute(
            "INSERT INTO issuances (ts, suffix, ttl) VALUES (?1, ?2, ?3)",
            rusqlite::params![ts, suffix, ttl as i64],
        );
    }

    /// (ts_min, rcvd, sent) for the trend chart.
    pub fn metrics_since(&self, since_min: i64) -> Vec<(i64, i64, i64)> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = match conn.prepare(
            "SELECT ts, traffic_rcvd, traffic_sent FROM metrics WHERE ts >= ?1 ORDER BY ts",
        ) {
            Ok(s) => s,
            Err(_) => return Vec::new(),
        };
        stmt.query_map(rusqlite::params![since_min], |row| {
            Ok((row.get(0)?, row.get(1)?, row.get(2)?))
        })
        .map(|rows| rows.filter_map(Result::ok).collect())
        .unwrap_or_default()
    }

    pub fn issuances(&self, limit: usize) -> Vec<(i64, String, i64)> {
        let conn = self.conn.lock().unwrap();
        let mut stmt =
            match conn.prepare("SELECT ts, suffix, ttl FROM issuances ORDER BY ts DESC LIMIT ?1") {
                Ok(s) => s,
                Err(_) => return Vec::new(),
            };
        stmt.query_map(rusqlite::params![limit as i64], |row| {
            Ok((row.get(0)?, row.get(1)?, row.get(2)?))
        })
        .map(|rows| rows.filter_map(Result::ok).collect())
        .unwrap_or_default()
    }
}

//! Prometheus scraper + snapshot types.

use crate::state::AppState;

#[derive(Debug, Default, Clone)]
pub struct Live {
    pub allocations_udp: i64,
    pub allocations_tcp: i64,
    pub traffic_rcvd: i64,
    pub traffic_sent: i64,
    pub prom_ok: bool,
}

pub async fn fetch_live(st: &AppState) -> Live {
    let mut live = Live::default();
    let Ok(resp) = st.http.get(&st.cfg.prom_url).send().await else {
        return live;
    };
    let Ok(resp) = resp.error_for_status() else {
        return live;
    };
    let Ok(body) = resp.text().await else {
        return live;
    };
    live.prom_ok = true;
    for line in body.lines() {
        if line.starts_with('#') {
            continue;
        }
        let mut parts = line.split_whitespace();
        let (Some(name), Some(value)) = (parts.next(), parts.next()) else {
            continue;
        };
        let value: i64 = value.parse().unwrap_or(0);
        if name.starts_with("turn_total_allocations") {
            if name.contains("type=\"udp\"") {
                live.allocations_udp = value;
            } else if name.contains("type=\"tcp\"") {
                live.allocations_tcp = value;
            }
        } else if let Some(rest) = name.strip_prefix("turn_total_traffic_rcvb") {
            if rest.is_empty() || rest.starts_with('{') {
                live.traffic_rcvd = value;
            }
        } else if let Some(rest) = name.strip_prefix("turn_total_traffic_sentb") {
            if rest.is_empty() || rest.starts_with('{') {
                live.traffic_sent = value;
            }
        }
    }
    live
}

pub async fn scrape_once(st: &AppState) {
    let live = fetch_live(st).await;
    if !live.prom_ok {
        return;
    }
    let ts_min = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
        / 60;
    st.store.record_metrics(
        ts_min,
        live.allocations_udp,
        live.allocations_tcp,
        live.traffic_rcvd,
        live.traffic_sent,
    );
}

pub async fn current_snapshot(st: &AppState) -> Live {
    fetch_live(st).await
}

pub fn live_json(live: &Live) -> serde_json::Value {
    serde_json::json!({
        "allocationsUdp": live.allocations_udp,
        "allocationsTcp": live.allocations_tcp,
        "trafficRcvd": live.traffic_rcvd,
        "trafficSent": live.traffic_sent,
    })
}

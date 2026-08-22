//! Hand-rolled SSR pages: layout, login, overview (with SVG trend
//! chart), credential issuing (deep link + QR), sessions table.
//! Self-contained — one stylesheet, no external assets.

use crate::collector::Live;
use crate::state::AppState;

fn esc(s: &str) -> String {
    s.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
}

fn layout(title: &str, body: &str) -> String {
    format!(
        "<!doctype html><html><head><meta charset=\"utf-8\">\
<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\
<title>{title} · localsend relay</title>\
<link rel=\"stylesheet\" href=\"/style.css\"></head>\
<body><nav><a href=\"/\">概览</a><a href=\"/issue\">签发凭据</a>\
<a href=\"/issue/history\">签发记录</a><a href=\"/sessions\">在线会话</a>\
<form method=\"post\" action=\"/logout\" class=\"inline\"><button>退出</button></form></nav>\
<main>{body}</main></body></html>"
    )
}

pub fn login(_st: &AppState, _err: Option<&str>) -> String {
    "<!doctype html><html><head><meta charset=\"utf-8\">\
<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">\
<title>登录 · localsend relay</title><link rel=\"stylesheet\" href=\"/style.css\"></head>\
<body><main class=\"card narrow\"><h1>localsend relay 面板</h1>\
<form method=\"post\" action=\"/login\">\
<input type=\"password\" name=\"password\" placeholder=\"管理员口令\" autofocus required>\
<button type=\"submit\">登录</button></form></main></body></html>"
        .to_string()
}

pub fn overview(st: &AppState, live: &Live) -> String {
    let since = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs() as i64
        / 60
        - 24 * 60;
    let series = st.store.metrics_since(since);
    let chart = trend_svg(&series, 880, 160);
    let prom = if live.prom_ok {
        "<span class=\"ok\">正常</span>"
    } else {
        "<span class=\"bad\">无法连接 coturn 指标端点</span>"
    };
    layout(
        "概览",
        &format!(
            "<h1>概览</h1>\
<div class=\"stats\">\
<div class=\"stat\"><b>{}</b><span>当前 UDP allocation</span></div>\
<div class=\"stat\"><b>{}</b><span>当前 TCP allocation</span></div>\
<div class=\"stat\"><b>{}</b><span>累计接收</span></div>\
<div class=\"stat\"><b>{}</b><span>累计发送</span></div>\
</div>\
<p>指标源：{prom}</p>\
<h2>近 24 小时流量趋势</h2>\
<div class=\"chart\">{chart}</div>\
<p class=\"muted\">分钟粒度自采集，保留 30 天。</p>",
            live.allocations_udp,
            live.allocations_tcp,
            human_bytes(live.traffic_rcvd),
            human_bytes(live.traffic_sent),
        ),
    )
}

/// Minute-resolution cumulative counters → per-hour delta columns.
fn trend_svg(series: &[(i64, i64, i64)], w: u32, h: u32) -> String {
    if series.len() < 2 {
        return "<p class=\"muted\">暂无历史数据（采集任务每分钟写入一次）。</p>".into();
    }
    let bucket = 60; // minutes per column (1h)
    let mut deltas: Vec<(i64, u64)> = Vec::new(); // (bucket_ts, delta bytes)
    let mut last_rcvd: Option<i64> = None;
    let mut last_sent: Option<i64> = None;
    let mut acc = 0u64;
    let mut cur_bucket = series[0].0 / bucket;
    for (ts, rcvd, sent) in series {
        let b = ts / bucket;
        if b != cur_bucket {
            deltas.push((cur_bucket, acc));
            acc = 0;
            cur_bucket = b;
        }
        let total = rcvd + sent;
        if let (Some(p), Some(q)) = (last_rcvd, last_sent) {
            let d = (total - (p + q)).max(0) as u64;
            acc = acc.saturating_add(d);
        }
        last_rcvd = Some(*rcvd);
        last_sent = Some(*sent);
    }
    deltas.push((cur_bucket, acc));

    let max = deltas.iter().map(|d| d.1).max().unwrap_or(1).max(1);
    let n = deltas.len() as f64;
    let bar_w = (w as f64 / n * 0.7).max(1.0);
    let gap = w as f64 / n;
    let mut bars = String::new();
    for (i, (ts, d)) in deltas.iter().enumerate() {
        let bh = (*d as f64 / max as f64) * (h as f64 - 24.0);
        let x = i as f64 * gap;
        let y = h as f64 - 18.0 - bh;
        let title = format!(
            "{} {}",
            crate::store_time(ts * bucket),
            human_bytes(*d as i64)
        );
        bars.push_str(&format!(
            "<rect x=\"{x:.1}\" y=\"{y:.1}\" width=\"{bar_w:.1}\" height=\"{bh:.1}\"><title>{}</title></rect>",
            esc(&title)
        ));
    }
    format!(
        "<svg viewBox=\"0 0 {w} {h}\" preserveAspectRatio=\"none\" role=\"img\">\
{bars}\
<text x=\"0\" y=\"{h}\" class=\"axis\">{} — {}（每小时流量，峰值 {}）</text></svg>",
        crate::store_time(deltas[0].0 * bucket),
        crate::store_time(deltas.last().unwrap().0 * bucket),
        human_bytes(max as i64),
    )
}

pub fn issue_form(_st: &AppState) -> String {
    layout(
        "签发凭据",
        "<h1>签发凭据</h1>\
<p>生成客户端一键配置（二维码/深链）与一对样例时效凭据。客户端拿到的是服务器地址与共享密钥，凭据由客户端按需自签。</p>\
<form method=\"post\" action=\"/issue\" class=\"card\">\
<label>有效期（秒，默认 1 小时 = 3600，1 天 = 86400）\
<input type=\"number\" name=\"ttl\" value=\"86400\" min=\"60\" max=\"2592000\"></label>\
<label>标签（用于日志辨识，可空）<input type=\"text\" name=\"suffix\" placeholder=\"desk\" maxlength=\"32\"></label>\
<button type=\"submit\">生成</button></form>",
    )
}

pub fn issue_result(
    st: &AppState,
    ttl: u64,
    suffix: &str,
    username: &str,
    password: &str,
) -> String {
    let link = format!(
        "localsend-relay://configure?addr={}&secret={}",
        urlencode(&st.cfg.relay_public_addr),
        urlencode(&st.cfg.relay_secret)
    );
    let qr = qr_svg(&link, 240);
    layout(
        "签发结果",
        &format!(
            "<h1>已生成（TTL {}，标签 {}）</h1>\
<div class=\"issue\">\
<div class=\"qr\">{qr}</div>\
<div class=\"issue-info\">\
<h2>客户端一键配置</h2>\
<p>移动端扫码，或复制下方链接：</p>\
<textarea readonly rows=\"3\" onclick=\"this.select()\">{}</textarea>\
<h2>样例凭据对</h2>\
<p class=\"muted\">username: <code>{}</code><br>password: <code>{}</code></p>\
<p><a href=\"/issue\">再签发一个</a> · <a href=\"/issue/history\">签发记录</a></p>\
</div></div>",
            human_duration(ttl),
            esc(suffix),
            esc(&link),
            esc(username),
            esc(password),
        ),
    )
}

pub fn issue_history(st: &AppState) -> String {
    let rows = st
        .store
        .issuances(50)
        .into_iter()
        .map(|(ts, suffix, ttl)| {
            format!(
                "<tr><td>{}</td><td>{}</td><td>{}</td></tr>",
                crate::store_time(ts),
                esc(&suffix),
                human_duration(ttl as u64)
            )
        })
        .collect::<Vec<_>>()
        .join("");
    layout(
        "签发记录",
        &format!(
            "<h1>签发记录</h1><table><tr><th>时间</th><th>标签</th><th>TTL</th></tr>{rows}</table>\
<p class=\"muted\">仅记录事件元数据，不保存凭据值。</p>"
        ),
    )
}

pub fn sessions(_st: &AppState) -> String {
    layout(
        "在线会话",
        "<h1>在线 TURN 会话</h1>\
<p class=\"muted\">每 5 秒自动刷新（轮询 coturn CLI）。</p>\
<table id=\"sessions\"><thead><tr><th>会话</th><th>用户</th><th>传输</th><th>接收</th><th>发送</th><th>速率</th><th>Peer</th><th></th></tr></thead><tbody></tbody></table>\
<script>
async function refresh() {{
  try {{
    const r = await fetch('/api/sessions');
    if (!r.ok) return;
    const d = await r.json();
    const tb = document.querySelector('#sessions tbody');
    tb.innerHTML = (d.sessions || []).map(s => `<tr>\
<td class=\"mono\">${{s.id.slice(0,10)}}</td><td>${{esc(s.user)}}</td><td>${{s.transport}}</td>\
<td>${{fmt(s.received_bytes)}}</td><td>${{fmt(s.sent_bytes)}}</td><td class=\"mono\">${{esc(s.rate)}}</td>\
<td class=\"mono\">${{esc(s.peers)}}</td>\
<td><button onclick=\"kick('${{s.id}}')\">踢除</button></td></tr>`).join('');
  }} catch (_) {{}}
}}
async function kick(id) {{
  if (!confirm('踢除会话 ' + id.slice(0,10) + '?')) return;
  await fetch('/api/sessions/' + id + '/kick', {{method: 'POST'}});
  refresh();
}}
const esc = s => String(s).replace(/[&<>\"']/g, c => ({{'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;',\"'\":'&#39;'}}[c]));
const fmt = b => b > 1048576 ? (b/1048576).toFixed(1)+' MB' : b > 1024 ? (b/1024).toFixed(1)+' KB' : b + ' B';
refresh();
setInterval(refresh, 5000);
</script>",
    )
}

fn qr_svg(data: &str, size: u32) -> String {
    use qrcode::render::svg::Color;
    use qrcode::QrCode;
    match QrCode::with_error_correction_level(data, qrcode::EcLevel::M) {
        Ok(code) => code
            .render::<Color>()
            .min_dimensions(size, size)
            .dark_color(Color("#111"))
            .light_color(Color("#fff"))
            .build(),
        Err(_) => "<p class=\"bad\">二维码生成失败（数据过长）</p>".into(),
    }
}

pub fn base64_of(data: &[u8]) -> String {
    use base64::Engine as _;
    base64::engine::general_purpose::STANDARD.encode(data)
}

fn urlencode(s: &str) -> String {
    let mut out = String::new();
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(b as char)
            }
            _ => out.push_str(&format!("%{b:02X}")),
        }
    }
    out
}

fn human_bytes(b: i64) -> String {
    let b = b.max(0) as f64;
    if b >= 1e9 {
        format!("{:.2} GB", b / 1e9)
    } else if b >= 1e6 {
        format!("{:.1} MB", b / 1e6)
    } else if b >= 1e3 {
        format!("{:.1} KB", b / 1e3)
    } else {
        format!("{b} B")
    }
}

fn human_duration(secs: u64) -> String {
    if secs >= 86400 {
        format!("{} 天", secs / 86400)
    } else if secs >= 3600 {
        format!("{} 小时", secs / 3600)
    } else {
        format!("{} 分钟", secs / 60)
    }
}

pub const CSS: &str = r#"
:root { color-scheme: light dark; }
* { box-sizing: border-box; }
body { font-family: system-ui, sans-serif; margin: 0; background: #f5f5f7; color: #1a1a1a; }
@media (prefers-color-scheme: dark) { body { background: #141416; color: #e6e6e6; } }
nav { display: flex; gap: 1rem; padding: .8rem 1.2rem; background: #2c2c2e; }
nav a, nav button { color: #e8e8e8; text-decoration: none; background: none; border: none; font: inherit; cursor: pointer; }
nav a:hover, nav button:hover { text-decoration: underline; }
nav .inline { margin-left: auto; }
main { max-width: 960px; margin: 1.5rem auto; padding: 0 1rem; }
h1 { font-size: 1.4rem; } h2 { font-size: 1.1rem; margin-top: 1.5rem; }
.card { background: #fff; border-radius: 12px; padding: 1.2rem; }
@media (prefers-color-scheme: dark) { .card { background: #1e1e20; } }
.narrow { max-width: 360px; margin: 15vh auto; }
input, textarea { width: 100%; padding: .5rem; margin: .3rem 0 .8rem; border: 1px solid #bbb; border-radius: 6px; font: inherit; }
textarea { font-family: ui-monospace, monospace; font-size: .8rem; }
button { background: #0071e3; color: #fff; border: none; border-radius: 6px; padding: .5rem 1.2rem; font: inherit; cursor: pointer; }
button:hover { background: #0077ed; }
.stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin: 1rem 0; }
.stat { background: #fff; border-radius: 12px; padding: 1rem; display: flex; flex-direction: column; }
@media (prefers-color-scheme: dark) { .stat { background: #1e1e20; } }
.stat b { font-size: 1.6rem; }
.chart svg { width: 100%; height: auto; }
.chart rect { fill: #0071e3; }
.axis { font-size: 11px; fill: #888; }
table { width: 100%; border-collapse: collapse; background: #fff; border-radius: 12px; overflow: hidden; }
@media (prefers-color-scheme: dark) { table { background: #1e1e20; } }
th, td { text-align: left; padding: .5rem .7rem; border-bottom: 1px solid #e2e2e2; font-size: .9rem; }
.mono { font-family: ui-monospace, monospace; font-size: .8rem; }
.muted { color: #888; font-size: .85rem; }
.ok { color: #34c759; } .bad { color: #ff453a; }
.issue { display: flex; gap: 2rem; flex-wrap: wrap; align-items: flex-start; }
.qr { background: #fff; padding: .8rem; border-radius: 12px; }
.issue-info { flex: 1; min-width: 280px; }
"#;

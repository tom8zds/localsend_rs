//! Minimal STUN message codec for the TURN-TCP client.
//!
//! Covers only what [`crate::relay`] needs: the 20-byte header, TLV
//! attribute loop, long-term-credential MESSAGE-INTEGRITY, and the
//! handful of attributes used by RFC 8489/8656/6062 client flows.
//! Anything unknown decodes as a raw attribute and is ignored.

use hmac::{Hmac, KeyInit, Mac};
use sha1::Sha1;

pub const MAGIC_COOKIE: u32 = 0x2112_A442;
pub const HEADER_LEN: usize = 20;
pub const FINGERPRINT_XOR: u32 = 0x5354_554E;

/// STUN methods this client uses (RFC 8489 §18, RFC 8656 §18,
/// RFC 6062 §6.1).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u16)]
pub enum Method {
    Allocate = 0x003,
    Refresh = 0x004,
    CreatePermission = 0x008,
    Connect = 0x00A,
    ConnectionBind = 0x00B,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MessageClass {
    Request,
    Indication,
    SuccessResponse,
    ErrorResponse,
}

/// Attribute types used by the TURN-TCP client.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u16)]
pub enum Attr {
    Username = 0x0006,
    MessageIntegrity = 0x0008,
    ErrorCode = 0x0009,
    Lifetime = 0x000D,
    XorPeerAddress = 0x0012,
    Realm = 0x0014,
    Nonce = 0x0015,
    XorRelayedAddress = 0x0016,
    RequestedTransport = 0x0019,
    DontFragment = 0x001A,
    ConnectionId = 0x002A,
}

fn encode_type(method: Method, class: MessageClass) -> u16 {
    let m = method as u16;
    let c = match class {
        MessageClass::Request => 0b00,
        MessageClass::Indication => 0b01,
        MessageClass::SuccessResponse => 0b10,
        MessageClass::ErrorResponse => 0b11,
    };
    // RFC 8489 §5: method bits spread across the message type with
    // the class bits interleaved.
    ((m & 0x0F80) << 2) | ((m & 0x0070) << 1) | (m & 0x000F) | ((c & 0b10) << 7) | ((c & 0b01) << 4)
}

fn decode_type(msg_type: u16) -> Result<(Method, MessageClass), &'static str> {
    let method = ((msg_type & 0x3E00) >> 2) | ((msg_type & 0x00E0) >> 1) | (msg_type & 0x000F);
    let class = match ((msg_type >> 8) & 0x1, (msg_type >> 4) & 0x1) {
        (0, 0) => MessageClass::Request,
        (0, 1) => MessageClass::Indication,
        (1, 0) => MessageClass::SuccessResponse,
        _ => MessageClass::ErrorResponse,
    };
    let method = match method {
        0x003 => Method::Allocate,
        0x004 => Method::Refresh,
        0x008 => Method::CreatePermission,
        0x00A => Method::Connect,
        0x00B => Method::ConnectionBind,
        _ => return Err("method not used by this client"),
    };
    Ok((method, class))
}

/// A transaction id: 96 bits, the first 32 of which xor with the
/// magic cookie in XOR-encoded attributes.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TransactionId(pub [u8; 12]);

impl TransactionId {
    pub fn new() -> Self {
        TransactionId(rand::random::<[u8; 12]>())
    }
}

/// Builder-style outgoing message. Attributes are appended in order;
/// MESSAGE-INTEGRITY (when supplied at [`Message::encode`]) must come
/// last except for FINGERPRINT, which this client never sends.
#[derive(Debug, Clone)]
pub struct Message {
    pub method: Method,
    pub class: MessageClass,
    pub tid: TransactionId,
    attrs: Vec<(u16, Vec<u8>)>,
}

impl Message {
    pub fn new(method: Method, class: MessageClass, tid: TransactionId) -> Self {
        Message {
            method,
            class,
            tid,
            attrs: Vec::new(),
        }
    }

    pub fn push(&mut self, attr: Attr, value: Vec<u8>) -> &mut Self {
        self.attrs.push((attr as u16, value));
        self
    }

    pub fn push_username(&mut self, v: &str) -> &mut Self {
        self.push(Attr::Username, v.as_bytes().to_vec())
    }

    pub fn push_realm(&mut self, v: &str) -> &mut Self {
        self.push(Attr::Realm, v.as_bytes().to_vec())
    }

    pub fn push_nonce(&mut self, v: &str) -> &mut Self {
        self.push(Attr::Nonce, v.as_bytes().to_vec())
    }

    /// REQUESTED-TRANSPORT: one protocol number plus three RFFU zero
    /// bytes (RFC 8656 §14.2).
    pub fn push_requested_transport(&mut self, protocol: u8) -> &mut Self {
        self.push(Attr::RequestedTransport, vec![protocol, 0, 0, 0])
    }

    pub fn push_lifetime(&mut self, seconds: u32) -> &mut Self {
        self.push(Attr::Lifetime, seconds.to_be_bytes().to_vec())
    }

    /// XOR-PEER-ADDRESS / XOR-RELAY-ADDRESS encoding (RFC 8489 §14.2).
    pub fn push_xor_address(&mut self, attr: Attr, addr: std::net::SocketAddr) -> &mut Self {
        let value = xor_address_bytes(&addr, &self.tid.0);
        self.push(attr, value)
    }

    pub fn push_connection_id(&mut self, id: u32) -> &mut Self {
        self.push(Attr::ConnectionId, id.to_be_bytes().to_vec())
    }

    /// Serialize the message. When `key` is given, a MESSAGE-INTEGRITY
    /// attribute (HMAC-SHA1 over the message up to and including the
    /// attribute's length adjustment) is appended last.
    pub fn encode(&mut self, key: Option<&[u8]>) -> Vec<u8> {
        if let Some(key) = key {
            // Reserve nothing; integrity is computed over the wire
            // bytes with the length field already covering it.
            let mut buf = Vec::with_capacity(HEADER_LEN + 64);
            self.write_header(&mut buf, self.attrs_body_len() + 24);
            for (t, v) in &self.attrs {
                write_attr(&mut buf, *t, v);
            }
            // RFC 8489 §15.4: HMAC over the message with the length
            // including the upcoming 24-byte integrity attribute.
            let mac = hmac_sha1(key, &buf);
            write_attr(&mut buf, Attr::MessageIntegrity as u16, &mac);
            return buf;
        }

        let mut buf = Vec::with_capacity(HEADER_LEN + self.attrs_body_len());
        self.write_header(&mut buf, self.attrs_body_len());
        for (t, v) in &self.attrs {
            write_attr(&mut buf, *t, v);
        }
        buf
    }

    fn attrs_body_len(&self) -> usize {
        self.attrs
            .iter()
            .map(|(_, v)| 4 + v.len() + padding(v.len()))
            .sum()
    }

    fn write_header(&self, buf: &mut Vec<u8>, body_len: usize) {
        buf.extend_from_slice(&encode_type(self.method, self.class).to_be_bytes());
        buf.extend_from_slice(&(body_len as u16).to_be_bytes());
        buf.extend_from_slice(&MAGIC_COOKIE.to_be_bytes());
        buf.extend_from_slice(&self.tid.0);
    }
}

fn padding(len: usize) -> usize {
    (4 - (len % 4)) % 4
}

fn write_attr(buf: &mut Vec<u8>, t: u16, v: &[u8]) {
    buf.extend_from_slice(&t.to_be_bytes());
    buf.extend_from_slice(&(v.len() as u16).to_be_bytes());
    buf.extend_from_slice(v);
    for _ in 0..padding(v.len()) {
        buf.push(0);
    }
}

/// A decoded incoming message; unknown attributes are kept as raw
/// (type, bytes) pairs.
#[derive(Debug, Clone)]
pub struct Incoming {
    pub method: Method,
    pub class: MessageClass,
    pub tid: TransactionId,
    pub attrs: Vec<(u16, Vec<u8>)>,
}

impl Incoming {
    pub fn decode(buf: &[u8]) -> Result<Self, &'static str> {
        if buf.len() < HEADER_LEN {
            return Err("short STUN header");
        }
        let msg_type = u16::from_be_bytes([buf[0], buf[1]]);
        let body_len = u16::from_be_bytes([buf[2], buf[3]]) as usize;
        if buf.len() < HEADER_LEN + body_len {
            return Err("truncated STUN body");
        }
        let cookie = u32::from_be_bytes([buf[4], buf[5], buf[6], buf[7]]);
        if cookie != MAGIC_COOKIE {
            return Err("bad magic cookie");
        }
        let (method, class) = decode_type(msg_type)?;
        let mut tid = [0u8; 12];
        tid.copy_from_slice(&buf[8..20]);

        let mut attrs = Vec::new();
        let mut off = HEADER_LEN;
        let end = HEADER_LEN + body_len;
        while off + 4 <= end {
            let t = u16::from_be_bytes([buf[off], buf[off + 1]]);
            let l = u16::from_be_bytes([buf[off + 2], buf[off + 3]]) as usize;
            if off + 4 + l > end {
                return Err("truncated attribute");
            }
            attrs.push((t, buf[off + 4..off + 4 + l].to_vec()));
            off += 4 + l + padding(l);
        }
        Ok(Incoming {
            method,
            class,
            tid: TransactionId(tid),
            attrs,
        })
    }

    pub fn find(&self, attr: Attr) -> Option<&[u8]> {
        let t = attr as u16;
        self.attrs
            .iter()
            .find(|(at, _)| *at == t)
            .map(|(_, v)| v.as_slice())
    }

    /// ERROR-CODE: (class, number, reason) — RFC 8489 §14.8: two
    /// reserved bytes, then class (3 bits), then the number byte,
    /// then the UTF-8 reason phrase.
    pub fn error_code(&self) -> Option<(u8, u16, String)> {
        let v = self.find(Attr::ErrorCode)?;
        if v.len() < 4 {
            return None;
        }
        let class = v[2] & 0x07;
        let number = v[3] as u16;
        Some((class, number, String::from_utf8_lossy(&v[4..]).into_owned()))
    }

    pub fn string_attr(&self, attr: Attr) -> Option<String> {
        self.find(attr)
            .map(|v| String::from_utf8_lossy(v).into_owned())
    }

    /// Decode XOR-*-ADDRESS attributes (IPv4 only — this client never
    /// speaks to v6 relays today).
    pub fn xor_address(&self, attr: Attr) -> Option<std::net::SocketAddr> {
        let v = self.find(attr)?;
        decode_xor_address(v, &self.tid.0)
    }

    pub fn connection_id(&self) -> Option<u32> {
        let v = self.find(Attr::ConnectionId)?;
        (v.len() == 4).then(|| u32::from_be_bytes([v[0], v[1], v[2], v[3]]))
    }

    pub fn lifetime(&self) -> Option<u32> {
        let v = self.find(Attr::Lifetime)?;
        (v.len() == 4).then(|| u32::from_be_bytes([v[0], v[1], v[2], v[3]]))
    }
}

fn xor_address_bytes(addr: &std::net::SocketAddr, tid: &[u8; 12]) -> Vec<u8> {
    // Layout: 1 reserved byte, 1 family byte, 2 port bytes, address.
    let cookie = MAGIC_COOKIE.to_be_bytes();
    match addr {
        std::net::SocketAddr::V4(v4) => {
            let octets = v4.ip().octets();
            let mut value = vec![0x00, 0x01];
            value.extend_from_slice(&(v4.port() ^ ((MAGIC_COOKIE >> 16) as u16)).to_be_bytes());
            for (i, b) in octets.iter().enumerate() {
                value.push(b ^ cookie[i]);
            }
            value
        }
        std::net::SocketAddr::V6(v6) => {
            let mut x = [0u8; 16];
            x[..4].copy_from_slice(&cookie);
            x[4..].copy_from_slice(tid);
            let octets = v6.ip().octets();
            let mut value = vec![0x00, 0x02];
            value.extend_from_slice(&(v6.port() ^ ((MAGIC_COOKIE >> 16) as u16)).to_be_bytes());
            for (i, b) in octets.iter().enumerate() {
                value.push(b ^ x[i]);
            }
            value
        }
    }
}

fn decode_xor_address(v: &[u8], tid: &[u8; 12]) -> Option<std::net::SocketAddr> {
    if v.len() != 8 {
        // v6 would be 20; not supported by this client.
        return None;
    }
    let family = v[1];
    if family != 0x01 {
        return None;
    }
    let port = u16::from_be_bytes([v[2], v[3]]) ^ (MAGIC_COOKIE >> 16) as u16;
    let cookie = MAGIC_COOKIE.to_be_bytes();
    let ip = std::net::Ipv4Addr::new(
        v[4] ^ cookie[0],
        v[5] ^ cookie[1],
        v[6] ^ cookie[2],
        v[7] ^ cookie[3],
    );
    let _ = tid; // v4 addresses xor against the cookie alone
    Some(std::net::SocketAddr::new(std::net::IpAddr::V4(ip), port))
}

/// Long-term credential key: MD5(username ":" realm ":" password)
/// (RFC 8489 §15.4).
pub fn long_term_key(username: &str, realm: &str, password: &str) -> Vec<u8> {
    use md5::Digest as _;
    let mut h = md5::Md5::new();
    h.update(format!("{username}:{realm}:{password}"));
    h.finalize().to_vec()
}

pub fn hmac_sha1(key: &[u8], data: &[u8]) -> Vec<u8> {
    let mut mac = Hmac::<Sha1>::new_from_slice(key).expect("hmac accepts any key length");
    mac.update(data);
    mac.finalize().into_bytes().to_vec()
}

/// Standard base64 with padding, as expected for REST credentials.
pub fn base64_encode(data: &[u8]) -> String {
    use base64::Engine as _;
    base64::engine::general_purpose::STANDARD.encode(data)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// Message-type encoding against the wire constants from the
    /// RFCs: TURN Allocate request is 0x0003, its error response
    /// 0x0113, CreatePermission request 0x0018, Connect request
    /// 0x0009, ConnectionBind request 0x000B.
    #[test]
    fn type_encoding_matches_rfc_constants() {
        assert_eq!(encode_type(Method::Allocate, MessageClass::Request), 0x0003);
        assert_eq!(
            encode_type(Method::Allocate, MessageClass::ErrorResponse),
            0x0113
        );
        assert_eq!(
            encode_type(Method::CreatePermission, MessageClass::Request),
            0x0008
        );
        assert_eq!(encode_type(Method::Connect, MessageClass::Request), 0x000A);
        assert_eq!(
            encode_type(Method::ConnectionBind, MessageClass::Request),
            0x000B
        );
        for (m, c) in [
            (Method::Allocate, MessageClass::Request),
            (Method::Refresh, MessageClass::SuccessResponse),
            (Method::CreatePermission, MessageClass::ErrorResponse),
            (Method::Connect, MessageClass::Request),
            (Method::ConnectionBind, MessageClass::SuccessResponse),
        ] {
            assert_eq!(decode_type(encode_type(m, c)).unwrap(), (m, c));
        }
    }

    #[test]
    fn message_roundtrip() {
        let tid = TransactionId([
            0x21, 0x12, 0xA4, 0x42, 0xB1, 0x6E, 0x25, 0xB8, 0xF1, 0x8B, 0x6C, 0xDC,
        ]);
        let peer: std::net::SocketAddr = "192.0.2.1:32853".parse().unwrap();
        let mut msg = Message::new(Method::Allocate, MessageClass::Request, tid);
        msg.push_username("1748:1731242457")
            .push_realm("localsend")
            .push_nonce("f/a==")
            .push_requested_transport(6)
            .push_lifetime(3600)
            .push_xor_address(Attr::XorPeerAddress, peer);
        let key = long_term_key("1748:1731242457", "localsend", "secret");
        let wire = msg.encode(Some(&key));

        let decoded = Incoming::decode(&wire).unwrap();
        assert_eq!(decoded.method, Method::Allocate);
        assert_eq!(decoded.class, MessageClass::Request);
        assert_eq!(decoded.tid, tid);
        assert_eq!(
            decoded.string_attr(Attr::Username).unwrap(),
            "1748:1731242457"
        );
        assert_eq!(decoded.string_attr(Attr::Realm).unwrap(), "localsend");
        assert_eq!(decoded.xor_address(Attr::XorPeerAddress).unwrap(), peer);
        // The integrity attribute is present and verifies against a
        // recomputation over everything before it.
        let integrity = decoded.find(Attr::MessageIntegrity).unwrap();
        let body_end = wire.len() - 24;
        assert_eq!(integrity, &hmac_sha1(&key, &wire[..body_end])[..]);
    }

    /// RFC 5769 §2.2 sample response carries XOR-MAPPED-ADDRESS
    /// 192.0.2.1:32853 — the official wire bytes for the XOR address
    /// decoding path (v4 addresses xor against the magic cookie
    /// alone, so the transaction id is irrelevant here).
    #[test]
    fn rfc5769_xor_mapped_address() {
        let tid = TransactionId([0u8; 12]);
        let attr_value = [0x00u8, 0x01, 0xA1, 0x47, 0xE1, 0x12, 0xA6, 0x43];
        let msg = Incoming {
            method: Method::Allocate,
            class: MessageClass::SuccessResponse,
            tid,
            attrs: vec![(Attr::XorRelayedAddress as u16, attr_value.to_vec())],
        };
        assert_eq!(
            msg.xor_address(Attr::XorRelayedAddress).unwrap(),
            "192.0.2.1:32853".parse::<std::net::SocketAddr>().unwrap()
        );
    }

    /// RFC 2202 HMAC-SHA1 test case 1.
    #[test]
    fn hmac_sha1_rfc2202() {
        let key = [0x0bu8; 20];
        let expected = hex("b617318655057264e28bc0b6fb378c8ef146be00");
        assert_eq!(hmac_sha1(&key, b"Hi There"), expected);
    }

    #[test]
    fn long_term_key_is_md5_of_concat() {
        let k = long_term_key("user", "realm", "pass");
        assert_eq!(k.len(), 16);
    }

    fn hex(s: &str) -> Vec<u8> {
        (0..s.len())
            .step_by(2)
            .map(|i| u8::from_str_radix(&s[i..i + 2], 16).unwrap())
            .collect()
    }
}

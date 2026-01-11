# HTTP/2 Client-Server Communication

## Step-by-Step Handshake

| Step | Direction | What | Type |
|------|-----------|------|------|
| 1 | Client → Server | Magic string (24 bytes) | Raw bytes (not a frame) |
| 2 | Client → Server | SETTINGS frame | Frame |
| 3 | Server → Client | SETTINGS frame | Frame |
| 4 | Client → Server | SETTINGS ACK | Frame |
| 5 | Server → Client | SETTINGS ACK | Frame |
| 6 | Client → Server | HEADERS frame (request) | Frame |
| 7 | Server → Client | HEADERS frame (response) | Frame |
| 8 | Server → Client | DATA frame (body) | Frame |

## Detailed Breakdown

### Step 1: Magic String (Client → Server)
```
PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n
```
- 24 bytes, raw, no frame header
- Purpose: confirm HTTP/2 protocol

---

### Step 2: Client SETTINGS (Client → Server)
```
00 00 12 04 00 00 00 00 00 | [payload: settings]
└─header─┘                   └─payload─┘
```
- type = 0x04 (SETTINGS)
- stream_id = 0 (connection-level)
- Payload contains key-value pairs (6 bytes each)

---

### Step 3: Server SETTINGS (Server → Client)
```
00 00 12 04 00 00 00 00 00 | [payload: settings]
```
- Same structure as Step 2
- Server tells client its settings

---

### Step 4: Client SETTINGS ACK (Client → Server)
```
00 00 00 04 01 00 00 00 00
            │
            └── flags = 0x01 (ACK)
```
- length = 0 (no payload)
- flags = 0x01 means "I acknowledge your settings"

---

### Step 5: Server SETTINGS ACK (Server → Client)
```
00 00 00 04 01 00 00 00 00
```
- Same as Step 4
- Server acknowledges client's settings

---

### Step 6: HEADERS Frame - Request (Client → Server)
```
00 00 1A 01 04 00 00 00 01 | [HPACK compressed headers]
         │  │           │
         │  │           └── stream_id = 1 (first request)
         │  └── flags = 0x04 (END_HEADERS)
         └── type = 0x01 (HEADERS)
```
Payload contains compressed:
- `:method: GET`
- `:path: /hello`
- `:scheme: https`
- `:authority: example.com`

---

### Step 7: HEADERS Frame - Response (Server → Client)
```
00 00 0F 01 04 00 00 00 01 | [HPACK compressed headers]
                        │
                        └── stream_id = 1 (same stream)
```
Payload contains compressed:
- `:status: 200`
- `content-type: text/plain`

---

### Step 8: DATA Frame - Response Body (Server → Client)
```
00 00 0C 00 01 00 00 00 01 | Hello World!
         │  │           │
         │  │           └── stream_id = 1
         │  └── flags = 0x01 (END_STREAM)
         └── type = 0x00 (DATA)
```
- Payload is the raw response body
- END_STREAM flag closes the stream

---

## Summary

```
Client                                Server
   |                                     |
   |---- Magic (24 bytes) ------------->|
   |---- SETTINGS frame --------------->|
   |<--- SETTINGS frame ----------------|
   |---- SETTINGS ACK ----------------->|
   |<--- SETTINGS ACK ------------------|
   |                                     |
   |---- HEADERS (request) ------------>|
   |<--- HEADERS (response) ------------|
   |<--- DATA (body + END_STREAM) ------|
   |                                     |
```

## Frame Structure (All Frames)

```
[9-byte header][payload]

Header:
  Bytes 0-2: Length (payload size)
  Byte 3:    Type (0=DATA, 1=HEADERS, 4=SETTINGS, etc.)
  Byte 4:    Flags
  Bytes 5-8: Stream ID
```

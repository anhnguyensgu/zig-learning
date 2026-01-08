# HTTP/2 Frame Format

Every HTTP/2 frame starts with a **9-byte header**:

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                 Length (24 bits)                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|   Type (8)    |   Flags (8)   |R|     Stream Identifier (31)  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                   ... Payload (Length bytes) ...              |
+---------------------------------------------------------------+
```

## Byte Layout (Big Endian / Network Order)

| Bytes | Field | Size | Description |
|-------|-------|------|-------------|
| 0-2 | Length | 24 bits | Payload size (NOT including 9-byte header) |
| 3 | Type | 8 bits | Frame type (0-9) |
| 4 | Flags | 8 bits | Type-specific flags |
| 5-8 | Stream ID | 31 bits | Stream identifier (bit 0 is reserved, always 0) |

## Frame Types

| Type | ID | Purpose |
|------|----|---------|
| DATA | 0x0 | Request/response body |
| HEADERS | 0x1 | HTTP headers (compressed) |
| PRIORITY | 0x2 | Stream priority |
| RST_STREAM | 0x3 | Cancel a stream |
| SETTINGS | 0x4 | Connection configuration |
| PUSH_PROMISE | 0x5 | Server push (not used by gRPC) |
| PING | 0x6 | Keep-alive / latency check |
| GOAWAY | 0x7 | Graceful shutdown |
| WINDOW_UPDATE | 0x8 | Flow control |
| CONTINUATION | 0x9 | Continued headers |

## Example Frame (Hex)

```
00 00 05 01 04 00 00 00 01 [payload: 5 bytes]
│  │  │  │  │  └─────────┘
│  │  │  │  │       └── Stream ID: 1
│  │  │  │  └── Flags: 0x04 (END_HEADERS)
│  │  │  └── Type: 0x01 (HEADERS)
│  │  └── Length: 0x000005 (5 bytes)
```

## What to Build

Create `src/http2/frame.zig`:

1. **FrameType enum** - Map the 10 types to values 0-9

2. **FrameHeader struct** - Hold the parsed header fields:
   - length: u24
   - frame_type: FrameType
   - flags: u8
   - stream_id: u31

3. **parseHeader function** - Take `[9]u8`, return `FrameHeader`
   - Read length from bytes 0-2 (big endian)
   - Read type from byte 3
   - Read flags from byte 4
   - Read stream_id from bytes 5-8 (big endian, mask off reserved bit)

## Zig Hints

Reading big-endian integers:
```zig
std.mem.readInt(u24, buffer[0..3], .big)
std.mem.readInt(u32, buffer[5..9], .big)
```

For stream_id, mask off the reserved bit:
```zig
stream_id & 0x7FFFFFFF  // Clear bit 31
```

## Test Your Parser

Send this from nc or a client:
```bash
# PING frame: length=8, type=6, flags=0, stream_id=0, payload=8 bytes
echo -ne '\x00\x00\x08\x06\x00\x00\x00\x00\x00\x01\x02\x03\x04\x05\x06\x07\x08' | nc localhost 8080
```

Your parser should extract:
- Length: 8
- Type: PING (6)
- Flags: 0
- Stream ID: 0

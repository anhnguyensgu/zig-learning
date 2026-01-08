# gRPC Implementation in Zig - Deep Dive Plan

## Part 1: How gRPC Works on Top of HTTP/2

### The gRPC Protocol Stack

```
┌─────────────────────────────────────┐
│         Application Code            │
├─────────────────────────────────────┤
│      Protocol Buffers (Protobuf)    │  ← Message serialization
├─────────────────────────────────────┤
│          gRPC Framing               │  ← Length-prefixed messages
├─────────────────────────────────────┤
│            HTTP/2                   │  ← Transport layer
├─────────────────────────────────────┤
│             TLS                     │  ← Optional encryption
├─────────────────────────────────────┤
│             TCP                     │  ← Network layer
└─────────────────────────────────────┘
```

### HTTP/2 Fundamentals (What gRPC Needs)

**1. Binary Framing Layer**
Unlike HTTP/1.1's text-based protocol, HTTP/2 uses binary frames:

```
HTTP/1.1:  "GET /path HTTP/1.1\r\nHost: example.com\r\n\r\n"

HTTP/2 Frame:
┌─────────────────────────────────────────────────┐
│ Length (24 bits) │ Type (8) │ Flags (8)         │
├─────────────────────────────────────────────────┤
│ R │          Stream Identifier (31 bits)        │
├─────────────────────────────────────────────────┤
│                Frame Payload                    │
└─────────────────────────────────────────────────┘
```

**2. Streams and Multiplexing**
- Each HTTP/2 connection has multiple **streams** (logical channels)
- Streams are identified by a 31-bit integer
- Client-initiated streams use odd numbers (1, 3, 5...)
- Server-initiated streams use even numbers (2, 4, 6...)
- Multiple requests/responses interleave on ONE TCP connection

```
TCP Connection
├── Stream 1: gRPC Call A (request)
├── Stream 1: gRPC Call A (response)
├── Stream 3: gRPC Call B (request)  ← Interleaved!
├── Stream 3: gRPC Call B (response)
└── Stream 5: gRPC Call C (streaming)
```

**3. Frame Types gRPC Uses**

| Frame Type | ID | Purpose in gRPC |
|------------|----|--------------|
| DATA       | 0  | Carries protobuf messages |
| HEADERS    | 1  | Method, path, status, metadata |
| SETTINGS   | 4  | Connection configuration |
| PING       | 6  | Keep-alive, latency measurement |
| GOAWAY     | 7  | Graceful shutdown |
| WINDOW_UPDATE | 8 | Flow control |
| RST_STREAM | 3  | Cancel a call |

**4. HPACK Header Compression**
HTTP/2 compresses headers using:
- Static table: 61 predefined headers
- Dynamic table: Connection-specific headers
- Huffman encoding for values

### gRPC Message Format (On Top of HTTP/2 DATA Frames)

Each gRPC message is wrapped in a **Length-Prefixed Message**:

```
┌─────────────────────────────────────────────────┐
│ Compressed Flag (1 byte) │ Message Length (4 bytes, big-endian) │
├─────────────────────────────────────────────────┤
│              Protobuf-encoded Message           │
└─────────────────────────────────────────────────┘
```

- Byte 0: `0x00` = uncompressed, `0x01` = compressed
- Bytes 1-4: Message length (network byte order)
- Bytes 5+: The actual protobuf payload

### gRPC Request/Response Flow

**1. Client Sends Request**
```
HEADERS frame (stream 1):
  :method = POST
  :scheme = https
  :path = /package.Service/Method
  :authority = server.example.com
  content-type = application/grpc
  te = trailers
  grpc-encoding = identity (or gzip)
  [custom metadata headers]

DATA frame (stream 1):
  [Length-Prefixed Message containing request protobuf]
```

**2. Server Sends Response**
```
HEADERS frame (stream 1):
  :status = 200
  content-type = application/grpc

DATA frame (stream 1):
  [Length-Prefixed Message containing response protobuf]

HEADERS frame (stream 1, END_STREAM):  ← "Trailers"
  grpc-status = 0
  grpc-message = (optional error message)
```

### gRPC Call Types Mapped to HTTP/2

| gRPC Type | Client Sends | Server Sends |
|-----------|--------------|--------------|
| Unary | 1 message | 1 message |
| Server Streaming | 1 message | N messages |
| Client Streaming | N messages | 1 message |
| Bidirectional | N messages | N messages |

All use the same HTTP/2 stream - the difference is how many DATA frames are sent.

---

## Part 2: Zig HTTP/2 Support Status

### Current State (as of Zig 0.13.x / 0.14.x)

**Zig's standard library (`std.http`) does NOT support HTTP/2.**

- `std.http.Client` - HTTP/1.1 only
- `std.http.Server` - HTTP/1.1 only
- No HPACK implementation
- No HTTP/2 framing

### What You'd Need to Build

To implement HTTP/2 from scratch, you need:

1. **TCP Socket Layer** ✅ (Zig has `std.net`)
2. **TLS Layer** ⚠️ (Zig has `std.crypto.tls` but limited)
3. **HTTP/2 Connection Preface** ❌ (build yourself)
4. **HTTP/2 Frame Parser/Serializer** ❌ (build yourself)
5. **HPACK Encoder/Decoder** ❌ (build yourself)
6. **Stream State Machine** ❌ (build yourself)
7. **Flow Control** ❌ (build yourself)

### Options for Proceeding

**Option A: Build HTTP/2 from Scratch (Recommended for Learning)**
- Implement RFC 7540 (HTTP/2) and RFC 7541 (HPACK)
- Maximum learning, significant effort
- You control everything

**Option B: Wrap a C Library**
- Use `nghttp2` (mature C HTTP/2 library) via Zig's C interop
- Less learning of HTTP/2 internals
- Production-ready quickly

**Option C: Use Zig Community Libraries**
- `zig-http2` exists but is experimental/incomplete
- May not be production-ready

---

## Part 3: High-Level Implementation Approach

### Recommended Layered Architecture

```
┌─────────────────────────────────────┐
│         Your Application            │
├─────────────────────────────────────┤
│    grpc_server.zig / grpc_client.zig │
├─────────────────────────────────────┤
│          proto_codec.zig            │  ← Protobuf encode/decode
├─────────────────────────────────────┤
│          grpc_framing.zig           │  ← Length-prefixed messages
├─────────────────────────────────────┤
│           http2/                    │
│  ├── connection.zig                 │  ← Connection management
│  ├── frame.zig                      │  ← Frame types & parsing
│  ├── hpack.zig                      │  ← Header compression
│  ├── stream.zig                     │  ← Stream state machine
│  └── flow_control.zig               │  ← Window management
├─────────────────────────────────────┤
│            std.net                  │
└─────────────────────────────────────┘
```

### Phase-by-Phase Build Plan

#### Phase 1: HTTP/2 Frame Layer
Build the binary protocol foundation:

```zig
// frame.zig
pub const FrameType = enum(u8) {
    data = 0x0,
    headers = 0x1,
    priority = 0x2,
    rst_stream = 0x3,
    settings = 0x4,
    push_promise = 0x5,
    ping = 0x6,
    goaway = 0x7,
    window_update = 0x8,
    continuation = 0x9,
};

pub const Frame = struct {
    length: u24,
    frame_type: FrameType,
    flags: u8,
    stream_id: u31,
    payload: []const u8,
};

pub fn parseFrame(reader: anytype) !Frame { ... }
pub fn serializeFrame(frame: Frame, writer: anytype) !void { ... }
```

#### Phase 2: HPACK Header Compression
Implement RFC 7541:

```zig
// hpack.zig
pub const HpackEncoder = struct {
    dynamic_table: DynamicTable,

    pub fn encode(self: *@This(), headers: []const Header) ![]u8 { ... }
};

pub const HpackDecoder = struct {
    dynamic_table: DynamicTable,

    pub fn decode(self: *@This(), encoded: []const u8) ![]Header { ... }
};
```

Key HPACK concepts:
- Indexed header field (1-bit prefix `1`)
- Literal header with indexing (2-bit prefix `01`)
- Literal without indexing (4-bit prefix `0000`)
- Integer encoding (variable-length with prefix)
- Huffman encoding table (static, 256 entries)

#### Phase 3: HTTP/2 Connection & Streams
Manage connection state:

```zig
// connection.zig
pub const Connection = struct {
    socket: std.net.Stream,
    streams: std.AutoHashMap(u31, Stream),
    hpack_encoder: HpackEncoder,
    hpack_decoder: HpackDecoder,
    settings: Settings,

    pub fn init(socket: std.net.Stream) !Connection { ... }
    pub fn sendPreface(self: *@This()) !void { ... }
    pub fn newStream(self: *@This()) !*Stream { ... }
    pub fn handleFrame(self: *@This(), frame: Frame) !void { ... }
};

// stream.zig
pub const StreamState = enum {
    idle,
    reserved_local,
    reserved_remote,
    open,
    half_closed_local,
    half_closed_remote,
    closed,
};

pub const Stream = struct {
    id: u31,
    state: StreamState,
    recv_window: i32,
    send_window: i32,
};
```

#### Phase 4: gRPC Framing
Add the gRPC message layer:

```zig
// grpc_framing.zig
pub const GrpcMessage = struct {
    compressed: bool,
    data: []const u8,
};

pub fn encodeMessage(data: []const u8, compressed: bool) ![]u8 {
    var buf: [5]u8 = undefined;
    buf[0] = if (compressed) 1 else 0;
    std.mem.writeInt(u32, buf[1..5], @intCast(data.len), .big);
    // Return buf ++ data
}

pub fn decodeMessage(reader: anytype) !GrpcMessage {
    const header = try reader.readBytesNoEof(5);
    const compressed = header[0] == 1;
    const len = std.mem.readInt(u32, header[1..5], .big);
    const data = try allocator.alloc(u8, len);
    try reader.readNoEof(data);
    return .{ .compressed = compressed, .data = data };
}
```

#### Phase 5: Protocol Buffers
Options for protobuf in Zig:

**Option A: Hand-write message types**
```zig
// For simple cases, manually implement encode/decode
pub const HelloRequest = struct {
    name: []const u8,

    pub fn encode(self: @This(), writer: anytype) !void { ... }
    pub fn decode(reader: anytype) !@This() { ... }
};
```

**Option B: Use zig-protobuf**
- Community library that generates Zig from .proto files
- https://github.com/Arwalk/zig-protobuf

**Option C: Use C protobuf via FFI**
- Wrap protobuf-c library

#### Phase 6: gRPC Server/Client API
Final user-facing layer:

```zig
// grpc_server.zig
pub fn Server(comptime ServiceDef: type) type {
    return struct {
        http2_conn: *Http2Connection,

        pub fn serve(self: *@This(), addr: std.net.Address) !void { ... }
        pub fn handleCall(self: *@This(), stream: *Stream) !void { ... }
    };
}

// Usage:
const server = try GrpcServer(MyService).init(allocator);
try server.serve(address);
```

---

## Chosen Approach: Pure Zig from Scratch

**Decision**: Build everything natively in Zig, referencing C libraries (nghttp2, protobuf-c) only for understanding.

### Why This is Valuable
- Deep understanding of every protocol layer
- No C dependencies to manage
- Learn Zig's strengths for binary protocol parsing
- Full control over memory and performance

### Reference Materials
- **nghttp2 source**: https://github.com/nghttp2/nghttp2 (especially `lib/nghttp2_frame.c`, `lib/nghttp2_hd.c`)
- **RFC 7540**: HTTP/2 specification
- **RFC 7541**: HPACK specification
- **gRPC over HTTP/2**: https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-HTTP2.md

### TLS Strategy

**Start with**: Plaintext HTTP/2 (h2c - HTTP/2 cleartext)
- Easier to debug with Wireshark/tcpdump
- `curl --http2-prior-knowledge` works without TLS
- Focus on protocol correctness first

**Add later**: TLS via `std.crypto.tls` or wrap OpenSSL
- Required for production gRPC (most clients expect TLS)
- ALPN negotiation for HTTP/2 (`h2` protocol identifier)

### Recommended Build Order

```
Logical build order:

1. HTTP/2 Frame Layer
   └── Parse/serialize the 9 frame types
   └── Test: echo frames back with netcat/custom client

2. HTTP/2 Connection Preface & Settings
   └── Client: send magic string + SETTINGS
   └── Server: receive preface, respond with SETTINGS
   └── Test: connect with curl --http2-prior-knowledge

3. HPACK (Header Compression)
   └── Static table (61 entries)
   └── Integer encoding (variable-length)
   └── String encoding (Huffman optional at first)
   └── Dynamic table
   └── Test: decode headers from curl, verify correctness

4. Stream Management
   └── Stream state machine (7 states)
   └── Flow control (WINDOW_UPDATE)
   └── Test: multiple concurrent requests

5. gRPC Framing
   └── Length-prefixed message encode/decode
   └── Trailers with grpc-status

6. Protobuf (Simple)
   └── Hand-write a few message types
   └── Understand varint, wire types

7. gRPC Server API
   └── Service definition pattern
   └── Test with grpcurl

8. gRPC Client API
   └── Channel/stub pattern
   └── Test against grpc-go server
```

### Project Structure

```
zgrpc/
├── build.zig
├── PLAN.md
├── src/
│   ├── main.zig              # Example usage
│   ├── http2/
│   │   ├── frame.zig         # Frame types, parse/serialize
│   │   ├── connection.zig    # Connection state, preface
│   │   ├── stream.zig        # Stream state machine
│   │   ├── hpack/
│   │   │   ├── encoder.zig
│   │   │   ├── decoder.zig
│   │   │   ├── huffman.zig   # Huffman table & codec
│   │   │   └── static_table.zig
│   │   └── flow_control.zig
│   ├── grpc/
│   │   ├── framing.zig       # Length-prefixed messages
│   │   ├── status.zig        # gRPC status codes
│   │   ├── server.zig
│   │   └── client.zig
│   └── proto/
│       └── (hand-written message types)
└── test/
    ├── frame_test.zig
    ├── hpack_test.zig
    └── integration_test.zig
```

---

## Verification Plan

1. **HTTP/2 layer**: Use `curl --http2-prior-knowledge` or `nghttp` CLI to test
2. **gRPC layer**: Use `grpcurl` to test against your server
3. **Interop**: Test against official gRPC servers (grpc-go, grpc-python)
4. **Unit tests**: Frame parsing, HPACK encoding, stream state machine

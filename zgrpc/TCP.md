Let's dive into TCP fundamentals - the foundation everything else sits on.

  TCP: What You Need to Know for HTTP/2

  The Socket API Model

  Server Side:                          Client Side:
  ┌─────────────┐                       ┌─────────────┐
  │   socket()  │  Create endpoint      │   socket()  │
  └──────┬──────┘                       └──────┬──────┘
         │                                     │
  ┌──────▼──────┐                              │
  │   bind()    │  Assign address:port         │
  └──────┬──────┘                              │
         │                                     │
  ┌──────▼──────┐                              │
  │  listen()   │  Mark as passive             │
  └──────┬──────┘                              │
         │                              ┌──────▼──────┐
         │◄─────── 3-way handshake ────►│  connect()  │
         │                              └──────┬──────┘
  ┌──────▼──────┐                              │
  │  accept()   │  Returns NEW socket          │
  └──────┬──────┘                              │
         │                                     │
         │◄──────── read()/write() ───────────►│
         │                                     │

  Key Concepts

  1. Connection-Oriented
  - TCP establishes a connection before data transfer
  - 3-way handshake: SYN → SYN-ACK → ACK
  - Both sides maintain state about the connection

  2. Byte Stream (Not Messages)
  You send:     "Hello" then "World"
  TCP sees:     H e l l o W o r l d  (just bytes)
  You receive:  Could be "Hell" then "oWorld" or "HelloWorld"

  This is critical: TCP has no message boundaries. HTTP/2 adds framing on top to define where messages start/end.

  3. Full Duplex
  - Both sides can send simultaneously
  - One socket, two independent streams (send & receive)

  4. Flow Control (TCP level)
  - Receiver advertises "window size" (how much it can buffer)
  - Sender must not exceed this
  - HTTP/2 adds its own flow control on top

  What Zig's std.net Gives You

  std.net.Server          -- Listening socket (bind + listen)
  std.net.Server.accept() -- Returns Connection
  std.net.Stream          -- The read/write handle (wrapper around fd)

  The Stream is essentially a file descriptor you read/write bytes to.

  The "No Message Boundary" Problem

  This is the #1 thing to internalize:

  // You might expect:
  client.write("FRAME1");
  client.write("FRAME2");

  // Server reads:
  server.read() → "FRAME1"  // Nice and clean
  server.read() → "FRAME2"

  // But reality could be:
  server.read() → "FRAM"      // Partial!
  server.read() → "E1FRAME2"  // Merged!

  Solution: You need a framing protocol. HTTP/2 solves this with:
  - 9-byte frame header
  - First 3 bytes = payload length
  - You read header, then read exactly that many payload bytes

  Blocking vs Non-Blocking

  Blocking (default):
  - read() waits until data arrives
  - accept() waits until client connects
  - Simple but can't handle multiple connections in one thread

  Non-Blocking:
  - read() returns immediately (EAGAIN if no data)
  - Requires event loop (epoll/kqueue) to know when data is ready
  - Zig's std.io has async support but it's evolving

  For learning, start with blocking + one connection. Add concurrency later.

  TCP Options Relevant to gRPC
  ┌──────────────┬───────────────────────────────────────┬───────────────────────────────────────────────┐
  │    Option    │                Purpose                │                gRPC Relevance                 │
  ├──────────────┼───────────────────────────────────────┼───────────────────────────────────────────────┤
  │ TCP_NODELAY  │ Disable Nagle's algorithm             │ gRPC typically enables this for lower latency │
  ├──────────────┼───────────────────────────────────────┼───────────────────────────────────────────────┤
  │ SO_KEEPALIVE │ Detect dead connections               │ gRPC uses HTTP/2 PING instead                 │
  ├──────────────┼───────────────────────────────────────┼───────────────────────────────────────────────┤
  │ SO_REUSEADDR │ Reuse address immediately after close │ Useful for server restarts during dev         │
  └──────────────┴───────────────────────────────────────┴───────────────────────────────────────────────┘
  Practical Exercise Suggestions

  Before HTTP/2, try these to feel TCP behavior:

  1. Echo server: Read bytes, write them back
  2. Observe fragmentation: Send large data, print each read() size
  3. Two clients: See what happens with blocking accept + one thread
  4. Manual HTTP/1.1: Send GET / HTTP/1.1\r\n\r\n, parse response

  The Mental Model for HTTP/2

  TCP gives you:    Reliable byte pipe
  You build:        Frame parser that reads fixed header → variable payload
  HTTP/2 gives you: Multiple logical streams on one TCP connection
  gRPC uses:        One stream per RPC call

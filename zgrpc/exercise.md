Exercise: Binary TCP Server/Client

  What to Build

  Server (in zgrpc/src/tcp_server.zig):
  1. Listen on a port (e.g., 8080)
  2. Accept one connection
  3. Read bytes into a buffer
  4. Print each byte as hex (e.g., 0x48 0x65 0x6c 0x6c 0x6f)
  5. Print how many bytes each read() returned

  Client (in zgrpc/src/tcp_client.zig):
  1. Connect to localhost:8080
  2. Send some raw bytes (not strings - think in bytes)
  3. Try sending a "fake frame header": 3 bytes length + 1 byte type + payload

  What to Observe

  1. Byte representation: Send [5]u8{0x00, 0x00, 0x05, 0x01, 0xFF} - see it arrive as raw bytes
  2. No message boundary:
    - Client: send 100 bytes, sleep, send 100 more
    - Server: observe read() might return 50, then 150, or 200 at once
  3. Endianness:
    - Send a u32 as big-endian (network order): std.mem.writeInt(u32, &buf, value, .big)
    - Server reads and interprets it
  4. Partial reads:
    - Send 1000 bytes
    - Server reads with small buffer (e.g., 64 bytes)
    - Count how many read() calls needed

  Zig Standard Library You'll Use

  std.net.Address.parseIp4()
  std.net.Address.listen()
  server.accept()
  connection.stream.read()
  connection.stream.write()
  std.net.tcpConnectToAddress()

  Suggested File Structure

  zgrpc/
  ├── build.zig
  ├── PLAN.md
  └── src/
      ├── tcp_server.zig    # Your server experiment
      └── tcp_client.zig    # Your client experiment

  Testing Without Client

  You can also test server with:
  # Send raw hex bytes
  echo -ne '\x00\x00\x05\x01\xff\x48\x65\x6c\x6c\x6f' | nc localhost 8080

  # Or use xxd to see what you're sending
  echo -ne '\x00\x00\x05\x01\xff' | xxd

  Go build it - let me know what you observe or if you hit any issues.

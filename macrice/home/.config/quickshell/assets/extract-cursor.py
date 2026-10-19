#!/usr/bin/env python3
# Pull one frame out of an XCursor file as a PNG (for the cursor ghost trail).
# Usage: extract-cursor.py <xcursor-file> <nominal-size> <out.png>   → prints "xhot yhot"
import struct, sys, zlib

path, want, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
data = open(path, "rb").read()
assert data[:4] == b"Xcur", "not an XCursor file"
_, _, ntoc = struct.unpack_from("<III", data, 4)
images = []
for i in range(ntoc):
    typ, size, pos = struct.unpack_from("<III", data, 16 + i * 12)
    if typ == 0xFFFD0002:
        images.append((size, pos))
size, pos = min(images, key=lambda s: (abs(s[0] - want), -s[0]))
_, _, _, _, w, h, xhot, yhot, _ = struct.unpack_from("<IIIIIIIII", data, pos)
px = data[pos + 36: pos + 36 + w * h * 4]

# ARGB (premultiplied, little endian) → straight RGBA rows for PNG
rows = b""
for y in range(h):
    row = bytearray(b"\x00")
    for x in range(w):
        b, g, r, a = px[(y * w + x) * 4:(y * w + x) * 4 + 4]
        if a:
            r, g, b = (min(255, c * 255 // a) for c in (r, g, b))
        row += bytes((r, g, b, a))
    rows += bytes(row)

def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) \
    + chunk(b"IDAT", zlib.compress(rows, 9)) + chunk(b"IEND", b"")
open(out, "wb").write(png)
print(xhot, yhot, w, h)

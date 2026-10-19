#!/usr/bin/env python3
# Prints "x y t" whenever the cursor moves (t = sample time in ms, monotonic).
# Polls Hyprland's request socket: 240 Hz while moving, ~16 Hz when still.
import json, os, socket, sys, time

sig = os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
run = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
path = f"{run}/hypr/{sig}/.socket.sock"
last, last_move = None, 0.0
parent = os.getppid()

while os.getppid() == parent:          # stop if the shell that started us goes away
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(path)
        s.sendall(b"j/cursorpos")
        data = b""
        while chunk := s.recv(256):
            data += chunk
        s.close()
        p = json.loads(data)
        pos = (p["x"], p["y"])
        now = time.monotonic()
        if pos != last:
            last, last_move = pos, now
            sys.stdout.write(f"{pos[0]} {pos[1]} {now * 1000:.1f}\n")
            sys.stdout.flush()
        time.sleep(1 / 240 if now - last_move < 0.4 else 1 / 16)
    except BrokenPipeError:              # the shell stopped reading: we're done
        break
    except (OSError, ValueError, KeyError):
        time.sleep(0.5)

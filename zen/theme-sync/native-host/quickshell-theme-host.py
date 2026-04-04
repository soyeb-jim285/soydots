#!/usr/bin/env python3
"""Native messaging host that watches ~/.config/zen-theme.json and sends updates to the extension."""

import json
import os
import struct
import sys
import time

THEME_PATH = os.path.expanduser("~/.config/zen-theme.json")
POLL_INTERVAL = 1.0


def send_message(msg):
    """Send a message to the extension using the native messaging protocol."""
    encoded = json.dumps(msg).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("@I", len(encoded)))
    sys.stdout.buffer.write(encoded)
    sys.stdout.buffer.flush()


def read_theme():
    """Read and parse the theme JSON file."""
    try:
        with open(THEME_PATH, "r") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def main():
    last_mtime = 0

    # Send initial theme
    theme = read_theme()
    if theme:
        send_message(theme)
        try:
            last_mtime = os.path.getmtime(THEME_PATH)
        except OSError:
            pass

    # Poll for changes
    while True:
        time.sleep(POLL_INTERVAL)
        try:
            mtime = os.path.getmtime(THEME_PATH)
            if mtime != last_mtime:
                last_mtime = mtime
                theme = read_theme()
                if theme:
                    send_message(theme)
        except OSError:
            pass


if __name__ == "__main__":
    main()

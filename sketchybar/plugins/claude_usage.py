#!/usr/bin/env python3
"""Печатает процент израсходованной сессии Claude и рисует к нему donut chart.

Вывод: "<percent> <png-path>" — sketchybar item читает обе части одной командой.

ponytail: PNG собирается вручную из zlib+struct, чтобы хватило системного
/usr/bin/python3 — под launchd homebrew-питона с PyObjC в PATH нет.
"""
import glob
import math
import os
import re
import struct
import zlib

HISTORY = os.path.expanduser(
    "~/Library/Application Support/Claude Usage/history/usageHistory_*.json"
)
SIZE = 44  # 22pt @2x
RADIUS = 17.0
WIDTH = 5.0
TRACK_ALPHA = 0.25  # серое кольцо-подложка; заполненная дуга рисуется в full alpha
TAU = 2 * math.pi


def percent():
    """Последний sessionPercentage из хвоста истории — файл весит мегабайты."""
    files = glob.glob(HISTORY)
    if not files:
        return None
    with open(max(files, key=os.path.getmtime), "rb") as f:
        f.seek(max(0, os.fstat(f.fileno()).st_size - 4096))
        tail = f.read().decode("utf-8", "replace")
    found = re.findall(r'"sessionPercentage"\s*:\s*(\d+)', tail)
    return int(found[-1]) if found else None


def pixels(pct):
    c = SIZE / 2.0
    edge = WIDTH / 2.0
    for y in range(SIZE):
        row = bytearray()
        for x in range(SIZE):
            dx, dy = x + 0.5 - c, y + 0.5 - c
            # сглаживание: доля пикселя, попавшая в кольцо
            cover = min(1.0, max(0.0, edge + 0.5 - abs(math.hypot(dx, dy) - RADIUS)))
            if cover:
                angle = math.atan2(dx, -dy) % TAU  # 0 = 12 часов, растёт по часовой
                filled = angle <= TAU * pct / 100.0
                cover *= 1.0 if filled else TRACK_ALPHA
            row += b"\xff" + bytes([round(cover * 255)])  # grayscale + alpha
        yield row


def png(pct, path):
    raw = b"".join(b"\x00" + bytes(row) for row in pixels(pct))

    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data))
        )

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 4, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))


def demo():
    """Самопроверка геометрии: дуга заполнена до pct и пуста после."""
    for pct in (4, 25, 50, 90):
        rows = [bytes(r) for r in pixels(pct)]

        def alpha_at(deg):
            a = math.radians(deg)
            x = int(SIZE / 2.0 + RADIUS * math.sin(a))
            y = int(SIZE / 2.0 - RADIUS * math.cos(a))
            return rows[y][2 * x + 1]

        edge = pct * 3.6
        assert alpha_at(edge - 8) > 200, (pct, "должно быть закрашено")
        assert alpha_at(edge + 8) < 120, (pct, "должно быть пусто")
    print("ok")


if __name__ == "__main__":
    pct = percent()
    if pct is not None:
        path = "/tmp/sketchybar-donut-%d.png" % pct
        if not os.path.exists(path):
            png(pct, path)
        print(pct, path)

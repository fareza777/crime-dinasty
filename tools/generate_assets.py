#!/usr/bin/env python3
"""Generate neo-noir pixel icons, launcher mipmaps, and simple original SFX."""
from __future__ import annotations

import math
import os
import struct
import subprocess
import wave
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path("/workspace")
NAVY = (11, 18, 32, 255)
NAVY2 = (18, 28, 48, 255)
CHAR = (22, 29, 43, 255)
RED = (139, 30, 63, 255)
GOLD = (201, 162, 39, 255)
GOLD2 = (232, 204, 110, 255)
CREAM = (232, 228, 217, 255)
DARK = (6, 10, 18, 255)


def pset(img: Image.Image, x: int, y: int, c, scale: int = 1):
    if scale == 1:
        if 0 <= x < img.size[0] and 0 <= y < img.size[1]:
            img.putpixel((x, y), c)
        return
    for dy in range(scale):
        for dx in range(scale):
            px, py = x * scale + dx, y * scale + dy
            if 0 <= px < img.size[0] and 0 <= py < img.size[1]:
                img.putpixel((px, py), c)


def draw_mark(size: int = 1024) -> Image.Image:
    """Pixel-art gold V over a rainy skyline, padded for adaptive icons."""
    grid = 32
    canvas = Image.new("RGBA", (grid, grid), (0, 0, 0, 0))
    # background circle-ish block for adaptive safe zone
    for y in range(grid):
        for x in range(grid):
            # keep transparent corners for adaptive foreground
            cx, cy = x - 15.5, y - 15.5
            if cx * cx + cy * cy < 15.6 * 15.6:
                t = y / grid
                c = (
                    int(NAVY[0] * (1 - t) + NAVY2[0] * t),
                    int(NAVY[1] * (1 - t) + 12 * t),
                    int(NAVY[2] * (1 - t) + 28 * t),
                    255,
                )
                canvas.putpixel((x, y), c)

    # skyline
    heights = [0, 0, 10, 14, 11, 18, 13, 20, 16, 12, 22, 15, 19, 11, 17, 13, 21, 14, 10, 16, 12, 18, 11, 9, 0, 0, 0, 0, 0, 0, 0, 0]
    for x in range(4, 28):
        h = heights[x] if x < len(heights) else 12
        for y in range(31 - h, 31):
            canvas.putpixel((x, y), CHAR if y > 31 - h + 1 else DARK)
        # red windows
        if h > 12 and x % 2 == 0:
            canvas.putpixel((x, 31 - h + 3), RED)
            if h > 16:
                canvas.putpixel((x, 31 - h + 6), GOLD)

    # crown / V monogram
    v = [
        (10, 8), (11, 9), (12, 11), (13, 13), (14, 15), (15, 17),
        (16, 15), (17, 13), (18, 11), (19, 9), (20, 8),
        (11, 8), (12, 10), (13, 12), (14, 14), (15, 16),
        (16, 14), (17, 12), (18, 10), (19, 8),
        (15, 7), (14, 6), (16, 6), (13, 6), (17, 6),
        (12, 7), (18, 7),
    ]
    for x, y in v:
        canvas.putpixel((x, y), GOLD)
    canvas.putpixel((15, 5), GOLD2)
    canvas.putpixel((15, 8), RED)

    img = canvas.resize((size, size), Image.NEAREST)
    return img


def draw_bg(size: int = 1024) -> Image.Image:
    img = Image.new("RGBA", (size, size), NAVY)
    d = ImageDraw.Draw(img)
    d.rectangle([0, int(size * 0.62), size, size], fill=NAVY2)
    return img


def save_png(img: Image.Image, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")


def write_wav(path: Path, samples, rate=22050):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s)))) for s in samples)
        w.writeframes(frames)


def tone(freq, ms, rate=22050, vol=0.28, fade=0.02):
    n = int(rate * ms / 1000)
    fn = int(rate * fade)
    out = []
    for i in range(n):
        t = i / rate
        s = math.sin(2 * math.pi * freq * t) * vol * 32767
        if i < fn:
            s *= i / max(1, fn)
        if i > n - fn:
            s *= (n - i) / max(1, fn)
        out.append(s)
    return out


def main():
    fg = draw_mark(1024)
    bg = draw_bg(1024)
    save_png(fg, ROOT / "assets/icons/foreground.png")
    save_png(bg, ROOT / "assets/icons/background.png")
    combined = Image.alpha_composite(bg, fg)
    save_png(combined, ROOT / "assets/icons/app_icon.png")
    save_png(combined.resize((192, 192), Image.NEAREST), ROOT / "web/icons/Icon-192.png")
    save_png(combined.resize((512, 512), Image.NEAREST), ROOT / "web/icons/Icon-512.png")
    save_png(combined.resize((32, 32), Image.NEAREST), ROOT / "web/favicon.png")

    mip = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }
    res = ROOT / "android/app/src/main/res"
    for dens, px in mip.items():
        icon = combined.resize((px, px), Image.NEAREST)
        save_png(icon, res / f"mipmap-{dens}/ic_launcher.png")
        # foreground with transparency (adaptive)
        fgs = fg.resize((px, px), Image.NEAREST)
        save_png(fgs, res / f"mipmap-{dens}/ic_launcher_foreground.png")
        bgs = bg.resize((px, px), Image.NEAREST)
        save_png(bgs, res / f"mipmap-{dens}/ic_launcher_background.png")

    # Play store / docs cover
    cover = Image.new("RGBA", (1024, 500), NAVY)
    mark = draw_mark(420)
    cover.paste(mark, (40, 40), mark)
    save_png(cover, ROOT / "assets/images/cover.png")

    # simple pixel portraits sheet placeholders
    palettes = [GOLD, RED, CREAM, (80, 140, 180, 255), (90, 90, 110, 255)]
    for i, pal in enumerate(palettes):
        p = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        for y in range(64):
            for x in range(64):
                if 18 < x < 46 and 8 < y < 58:
                    p.putpixel((x, y), CHAR if y < 22 else pal)
        save_png(p.resize((128, 128), Image.NEAREST), ROOT / f"assets/images/portrait_{i}.png")

    sfx = ROOT / "assets/sfx"
    write_wav(sfx / "tap.wav", tone(880, 70, vol=0.22))
    write_wav(sfx / "success.wav", tone(523, 90) + tone(784, 140, vol=0.3))
    write_wav(sfx / "fail.wav", tone(196, 180, vol=0.3) + tone(147, 120, vol=0.22))
    write_wav(sfx / "year.wav", tone(392, 100) + tone(494, 160, vol=0.26))
    write_wav(sfx / "legacy.wav", tone(261, 140) + tone(330, 140) + tone(392, 220, vol=0.28))
    write_wav(sfx / "card.wav", tone(640, 50, vol=0.18) + tone(720, 40, vol=0.14))
    print("assets generated")


if __name__ == "__main__":
    main()

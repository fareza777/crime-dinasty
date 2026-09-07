#!/usr/bin/env python3
"""Copy generated character portraits into Flutter assets and downscale."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

SRC = Path("/opt/cursor/artifacts/assets")
DEST = Path("/workspace/assets/images/portraits")
LEGACY = Path("/workspace/assets/images")

NAMES = [
    "player_man",
    "player_woman",
    "player_nb",
    "sibling",
    "mentor",
    "vale",
    "cass",
    "mira",
    "ben",
    "matriarch",
    "enforcer",
    "child",
    "spouse_man",
    "spouse_woman",
    "vex",
    "nessa",
    "parent_man",
    "crew_woman",
    "teen_girl",
    "cousin",
]


def fit_square(im: Image.Image, size: int) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    im = im.crop((left, top, left + side, top + side))
    return im.resize((size, size), Image.Resampling.LANCZOS)


def main() -> None:
    DEST.mkdir(parents=True, exist_ok=True)
    n = 0
    for name in NAMES:
        src = SRC / f"port_{name}.png"
        if not src.exists():
            print(f"missing {src}")
            continue
        im = fit_square(Image.open(src), 192)
        dest = DEST / f"{name}.png"
        im.save(dest, format="PNG", optimize=True, compress_level=9)
        n += 1
        print(f"wrote {dest} ({dest.stat().st_size} bytes)")

    # Keep legacy chips pointing at five obviously different faces.
    legacy_map = {
        0: "player_man",
        1: "vale",
        2: "mentor",
        3: "matriarch",
        4: "enforcer",
    }
    for i, key in legacy_map.items():
        src = DEST / f"{key}.png"
        if src.exists():
            Image.open(src).save(LEGACY / f"portrait_{i}.png", format="PNG", optimize=True, compress_level=9)

    print(f"packed {n} portraits")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Downscale packed art so the APK stays a mobile download, not a gallery dump."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path("/workspace/assets")


def fit(im: Image.Image, max_w: int, max_h: int) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    scale = min(max_w / w, max_h / h, 1.0)
    if scale >= 0.999:
        return im
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    return im.resize((nw, nh), Image.Resampling.LANCZOS)


def save(im: Image.Image, path: Path) -> None:
    im.save(path, format="PNG", optimize=True, compress_level=9)


def main() -> None:
    rules: list[tuple[str, int, int]] = [
        ("icons/app_icon.png", 512, 512),
        ("icons/foreground.png", 432, 432),
        ("icons/background.png", 432, 432),
        ("images/splash.png", 720, 1080),
        ("images/logo_plate.png", 960, 640),
        ("images/cover.png", 1024, 640),
        ("images/title_poster.png", 720, 960),
        ("images/events/panel_rain.png", 960, 540),
        ("images/hall.png", 960, 640),
        ("images/empty_chair.png", 960, 640),
        ("images/crew.png", 512, 512),
        ("images/dossier_frame.png", 512, 512),
        ("images/year_banner.png", 960, 240),
    ]
    for name, w, h in rules:
        p = ROOT / name
        if p.exists():
            save(fit(Image.open(p), w, h), p)

    for p in (ROOT / "icons").glob("*.png"):
        if p.name in {"app_icon.png", "foreground.png", "background.png"}:
            continue
        save(fit(Image.open(p), 128, 128), p)

    for folder, size in (
        ("images/events", (768, 512)),
        ("images/districts", (768, 512)),
        ("images/crests", (256, 256)),
        ("images/chrome", (640, 400)),
        ("images/headers", (768, 432)),
        ("images/activities", (192, 192)),
        ("images/fronts", (768, 432)),
    ):
        d = ROOT / folder
        if not d.exists():
            continue
        for p in d.glob("*.png"):
            save(fit(Image.open(p), size[0], size[1]), p)

    for p in (ROOT / "images").glob("portrait_*.png"):
        save(fit(Image.open(p), 192, 192), p)

    portraits = ROOT / "images/portraits"
    if portraits.exists():
        for p in portraits.glob("*.png"):
            save(fit(Image.open(p), 192, 192), p)

    n = sum(1 for _ in ROOT.rglob("*.png"))
    kb = sum(p.stat().st_size for p in ROOT.rglob("*.png")) / 1024
    print(f"optimized {n} pngs, {kb:.0f} KB")


if __name__ == "__main__":
    main()

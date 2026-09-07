#!/usr/bin/env python3
"""Copy generated neo-noir art into Flutter assets and Android mipmaps."""
from __future__ import annotations

import os
import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SRC = Path("/opt/cursor/artifacts/assets")
ROOT = Path("/workspace")
IMG = ROOT / "assets" / "images"
ICO = ROOT / "assets" / "icons"
RES = ROOT / "android" / "app" / "src" / "main" / "res"

MAP = {
    "vd_splash.png": IMG / "splash.png",
    "vd_logo_plate.png": IMG / "logo_plate.png",
    "vd_cover.png": IMG / "cover.png",
    "vd_icon.png": ICO / "app_icon.png",
    "vd_hall.png": IMG / "hall.png",
    "vd_empty_chair.png": IMG / "empty_chair.png",
    "vd_crew.png": IMG / "crew.png",
    "vd_dossier_frame.png": IMG / "dossier_frame.png",
    "vd_year_banner.png": IMG / "year_banner.png",
    "vd_event_crime.png": IMG / "events/crime_night.png",
    "vd_event_family.png": IMG / "events/family_dinner.png",
    "vd_event_court.png": IMG / "events/courtroom.png",
    "vd_event_docks.png": IMG / "events/docks_heist.png",
    "vd_event_betrayal.png": IMG / "events/betrayal.png",
    "vd_event_wedding.png": IMG / "events/wedding.png",
    "vd_event_prison.png": IMG / "events/prison.png",
    "vd_event_funeral.png": IMG / "events/funeral.png",
    "vd_event_club.png": IMG / "events/club.png",
    "vd_event_office.png": IMG / "events/office.png",
    "vd_event_home.png": IMG / "events/home.png",
    "vd_event_skyline.png": IMG / "events/skyline.png",
    "vd_event_ledger.png": IMG / "events/ledger.png",
    "vd_event_prosecutor.png": IMG / "events/prosecutor.png",
    "vd_dist_docks.png": IMG / "districts/docks.png",
    "vd_dist_midtown.png": IMG / "districts/midtown.png",
    "vd_dist_oldquarter.png": IMG / "districts/old_quarter.png",
    "vd_dist_glassridge.png": IMG / "districts/glassridge.png",
    "vd_dist_flats.png": IMG / "districts/the_flats.png",
    "vd_dist_harbor.png": IMG / "districts/harbor_lights.png",
    "vd_dist_ironyard.png": IMG / "districts/ironyard.png",
    "vd_dist_westmere.png": IMG / "districts/westmere.png",
    "vd_crest_calderas.png": IMG / "crests/calderas.png",
    "vd_crest_rooke.png": IMG / "crests/rooke.png",
    "vd_crest_vex.png": IMG / "crests/vex.png",
    "vd_crest_marrow.png": IMG / "crests/marrow.png",
    "vd_ico_life.png": ICO / "life.png",
    "vd_ico_family.png": ICO / "family.png",
    "vd_ico_city.png": ICO / "city.png",
    "vd_ico_empire.png": ICO / "empire.png",
    "vd_ico_more.png": ICO / "more.png",
    "vd_ico_activities.png": ICO / "activities.png",
    "vd_ico_business.png": ICO / "business.png",
    "vd_ico_relations.png": ICO / "relationships.png",
    "vd_ico_court.png": ICO / "court.png",
    "vd_ico_legacy.png": ICO / "legacy.png",
    "vd_ico_settings.png": ICO / "settings.png",
    "vd_stat_health.png": ICO / "stat_health.png",
    "vd_stat_int.png": ICO / "stat_int.png",
    "vd_stat_cha.png": ICO / "stat_cha.png",
    "vd_stat_nerve.png": ICO / "stat_nerve.png",
    "vd_stat_loyalty.png": ICO / "stat_loyalty.png",
    "vd_stat_rep.png": ICO / "stat_rep.png",
    "vd_stat_heat.png": ICO / "stat_heat.png",
    "vd_stat_stress.png": ICO / "stat_stress.png",
    "vd_stat_cash.png": ICO / "stat_cash.png",
    "vd_chrome_panel.png": IMG / "chrome/panel.png",
    "vd_chrome_btn_primary.png": IMG / "chrome/btn_primary.png",
    "vd_chrome_btn_danger.png": IMG / "chrome/btn_danger.png",
    "vd_chrome_btn_ghost.png": IMG / "chrome/btn_ghost.png",
    "vd_chrome_choice.png": IMG / "chrome/choice.png",
    "vd_portrait_0.png": IMG / "portrait_0.png",
    "vd_portrait_1.png": IMG / "portrait_1.png",
    "vd_portrait_2.png": IMG / "portrait_2.png",
    "vd_portrait_3.png": IMG / "portrait_3.png",
    "vd_portrait_4.png": IMG / "portrait_4.png",
}

ALIASES = {
    IMG / "events/street.png": IMG / "events/crime_night.png",
    IMG / "events/heist.png": IMG / "events/docks_heist.png",
    IMG / "events/docks.png": IMG / "events/docks_heist.png",
    IMG / "events/court.png": IMG / "events/courtroom.png",
    IMG / "events/legacy.png": IMG / "events/funeral.png",
}


def copy_named() -> int:
    n = 0
    for src_name, dest in MAP.items():
        src = SRC / src_name
        if not src.exists():
            print(f"skip missing {src_name}")
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        n += 1
    for dest, src in ALIASES.items():
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        n += 1
    return n


def square_icon(src: Path, size: int, pad: float = 0.18) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    # Crop center square then fit with padding for adaptive safe zone.
    w, h = im.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    im = im.crop((left, top, left + side, top + side))
    canvas = Image.new("RGBA", (size, size), (11, 18, 32, 255))
    inner = int(size * (1 - pad * 2))
    im = im.resize((inner, inner), Image.Resampling.LANCZOS)
    off = (size - inner) // 2
    canvas.paste(im, (off, off), im)
    return canvas


def write_mipmaps() -> None:
    icon = SRC / "vd_icon.png"
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    fg_sizes = {
        "mipmap-mdpi": 108,
        "mipmap-hdpi": 162,
        "mipmap-xhdpi": 216,
        "mipmap-xxhdpi": 324,
        "mipmap-xxxhdpi": 432,
    }
    for folder, size in densities.items():
        d = RES / folder
        d.mkdir(parents=True, exist_ok=True)
        square_icon(icon, size, pad=0.08).save(d / "ic_launcher.png")
    for folder, size in fg_sizes.items():
        d = RES / folder
        d.mkdir(parents=True, exist_ok=True)
        square_icon(icon, size, pad=0.22).save(d / "ic_launcher_foreground.png")
    # Adaptive layers for Flutter assets
    square_icon(icon, 432, pad=0.22).save(ICO / "foreground.png")
    bg = Image.new("RGBA", (432, 432), (11, 18, 32, 255))
    bg.save(ICO / "background.png")


def chrome() -> None:
    """Simple gold-frame button plates so Material isn't the only surface."""
    chrome_dir = IMG / "chrome"
    chrome_dir.mkdir(parents=True, exist_ok=True)

    def plate(path: Path, fill, border, w=512, h=128, radius=22):
        im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        d.rounded_rectangle((4, 4, w - 5, h - 5), radius=radius, fill=fill, outline=border, width=3)
        d.rounded_rectangle((10, 10, w - 11, h - 11), radius=radius - 6, outline=(232, 204, 110, 90), width=1)
        im.save(path)

    plate(chrome_dir / "btn_primary.png", (201, 162, 39, 255), (232, 204, 110, 255))
    plate(chrome_dir / "btn_danger.png", (139, 30, 63, 255), (196, 92, 106, 255))
    plate(chrome_dir / "btn_ghost.png", (22, 29, 43, 220), (201, 162, 39, 160))
    # Panel
    w, h = 640, 400
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((6, 6, w - 7, h - 7), radius=18, fill=(16, 22, 36, 235), outline=(201, 162, 39, 140), width=2)
    d.rounded_rectangle((14, 14, w - 15, h - 15), radius=12, outline=(139, 30, 63, 70), width=1)
    im.save(chrome_dir / "panel.png")
    # Choice card
    plate(chrome_dir / "choice.png", (18, 26, 42, 240), (201, 162, 39, 180), w=640, h=160, radius=16)


def main() -> None:
    IMG.mkdir(parents=True, exist_ok=True)
    ICO.mkdir(parents=True, exist_ok=True)
    chrome()
    n = copy_named()
    write_mipmaps()
    count = sum(1 for p in (IMG.rglob("*.png")) ) + sum(1 for p in ICO.rglob("*.png"))
    print(f"copied {n} named files; total png under assets/images+icons = {count}")


if __name__ == "__main__":
    main()

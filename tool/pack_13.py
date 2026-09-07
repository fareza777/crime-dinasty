#!/usr/bin/env python3
from pathlib import Path
from PIL import Image

SRC = Path("/opt/cursor/artifacts/assets")
IMG = Path("/workspace/assets/images")
ICO = Path("/workspace/assets/icons")

MAP = {
    "vd_empty_crew.png": IMG / "empty_crew.png",
    "vd_empty_shop2.png": IMG / "empty_shop.png",
    "vd_empty_court2.png": IMG / "empty_court.png",
    "vd_empty_hall2.png": IMG / "empty_hall.png",
    "vd_empty_ledger.png": IMG / "empty_ledger.png",
    "vd_empty_relations.png": IMG / "empty_relations.png",
    "vd_empty_activities.png": IMG / "empty_activities.png",
    "vd_tip_compass.png": ICO / "tip_compass.png",
    "vd_header_family.png": IMG / "headers/family.png",
    "vd_header_city2.png": IMG / "headers/city.png",
    "vd_header_activities.png": IMG / "headers/activities.png",
    "vd_header_business.png": IMG / "headers/business.png",
    "vd_header_court.png": IMG / "headers/court.png",
    "vd_header_legacy.png": IMG / "headers/legacy.png",
    "vd_header_relations.png": IMG / "headers/relations.png",
    "vd_header_empire.png": IMG / "headers/empire.png",
    "vd_header_settings.png": IMG / "headers/settings.png",
    "vd_act_earn2.png": IMG / "activities/earn.png",
    "vd_act_risk2.png": IMG / "activities/risk.png",
    "vd_act_family2.png": IMG / "activities/family.png",
    "vd_act_cool2.png": IMG / "activities/cool.png",
    "vd_front_club.png": IMG / "fronts/club.png",
    "vd_front_shipping.png": IMG / "fronts/shipping.png",
    "vd_front_laundry.png": IMG / "fronts/laundry.png",
}


def fit(im: Image.Image, max_w: int, max_h: int) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    scale = min(max_w / w, max_h / h, 1.0)
    if scale < 0.999:
        im = im.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.LANCZOS)
    return im


def main() -> None:
    n = 0
    for src_name, dest in MAP.items():
        src = SRC / src_name
        if not src.exists():
            print("missing", src_name)
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        if "tip_compass" in src_name or "/activities/" in str(dest):
            max_w, max_h = 192, 192
        elif "/icons/" in str(dest):
            max_w, max_h = 192, 192
        else:
            max_w, max_h = 768, 432
        im = fit(Image.open(src), max_w, max_h)
        im.save(dest, format="PNG", optimize=True, compress_level=9)
        n += 1
        print(dest, dest.stat().st_size)
    print("packed", n)


if __name__ == "__main__":
    main()

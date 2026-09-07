# Vice Dynasty

**Crime Life Simulator** — a one-handed, offline neo-noir life sim about building a criminal family in **Ravenport**.

You play **one year at a time**. Each year you do three things:

1. **What happens this year** — read the card, pick a choice
2. **Do something** (optional) — Earn, Risk, Family, or Cool down
3. **Next year** — age up

When you die or retire, you pick who takes over. The family keeps money, turf, and enemies.

**Empire** (More → Empire) is the books: hire, pay, assign crew, invest, and **open a front** when you can stand the cash. Years can still gift a key. Unaffordable buttons say how much more you need.

**Dynasty** draws a real family tree (elders, chair, children, circle). **War season** turns a hot rival into threat → escalation → resolution on Life and City.

**City** streets can be pressed or cooled. **Family:** Sit with **one** person per year; Gift also **one** person per year (separate from Sit). Life shows a year-close card and a short ambition after each year.

A guided spotlight tour (Skip / Next, Step N of 14) cuts a hole around the real control, pulses a gold ring, and advances when you tap that control. It walks New Game, the year loop, Family, City, and More. Replay it from Help.

This is stylized crime **fiction**. It is not a guide to real-world crime.

## Play

```bash
flutter pub get
flutter run
```

Portrait Android is the target. A web build exists for preview. Local saves only — no accounts, no backend.

Settings: **Dark mode** is the default (neo-noir navy). Soft paper light stays available as a toggle. Music and SFX have volume. Audio fails soft if a file cannot load.

## Build

See [docs/BUILD.md](docs/BUILD.md) for APK / AAB, AdMob IDs, and IAP.

Play Store copy: [docs/PLAY_STORE.md](docs/PLAY_STORE.md)  
Art inventory: [docs/ASSETS.md](docs/ASSETS.md)  
QA: [docs/TEST_CHECKLIST.md](docs/TEST_CHECKLIST.md)

## APK

Release APK (debug-signed for sideload), **1.9.3+16**:

`artifacts/vice-dynasty-release.apk`

SHA-256: `8866b0f643e24121e093f21b50388af0ca054408139dd65f2d97f2b20a08b8ba`  
Size: `72568831` bytes (69.2 MB)

Also copied to `/opt/cursor/artifacts/vice-dynasty-release.apk` and `/opt/cursor/artifacts/vice-dynasty-1.9.3.apk`.

Temporary downloads (48h tmpfiles; gofile guest):

- Landing: https://tmpfiles.org/wSwvkDR0gN6I/vice-dynasty-release.apk
- Direct `/dl/` (verified `Content-Type: application/vnd.android.package-archive`): https://tmpfiles.org/dl/1788672501.261b637a082e0474/wSwvkDR0gN6I/vice-dynasty-release.apk
- Gofile: https://gofile.io/d/IRZltZ2f

Phone previews live in `docs/preview/` (dark mosaic default + More/Dynasty/Settings/Life/Family; paper Life for the toggle). Play listing notes: [docs/PLAY_STORE.md](docs/PLAY_STORE.md).

Dark mosaic `/dl/`: https://tmpfiles.org/dl/1788672515.804e0a4c066e98fb/wfwckDRagaTg/00_mosaic_dark.png

ABIs: armeabi-v7a, arm64-v8a, x86_64. Ads/IAP fail-soft; AdMob does not init at process start (`MobileAdsInitProvider` removed). Crash-safe path from 1.0.1 is kept.

Application id: `com.vicedynasty.life`

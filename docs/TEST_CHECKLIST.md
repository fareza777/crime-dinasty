# Test checklist

Automated coverage: `flutter test` (engine + widget). The cases below were also exercised by those tests or by a headless loop in this repo.

## Core loop

- [x] New game starts in Ravenport, age 18, year 1998, with stats, rival families, and districts
- [x] Age-up advances year, writes timeline / year summary
- [x] Activities exist every year (`lay_low` at minimum) — no empty-year softlock
- [x] Crime activity can pay, raise heat, injure, or arrest
- [x] Prison restricts street jobs, still allows prison activities, then releases
- [x] Life sentence opens heir selection
- [x] Child is born, gains traits at 12/16, adulthood at 18
- [x] Death → eligible heir → select heir → generation +1
- [x] Inheritance keeps money, businesses, turf; heat/reputation are family-memory scaled; Hall of Legacy records the last leader
- [x] After heir, age-up still works (keep playing)
- [x] Save slot round-trip preserves flags, money, businesses, turf
- [x] Multi-year loop (draw event → choose → age-up ×12) does not crash
- [x] Prologue: first draw is `prologue_rain`; take sets `first_mark`; next year draws `prologue_heat`
- [x] Quiet Pier: look sets `quiet_pier_looked`; next year queues `quiet_pier_crate`
- [x] Mentors/foils are not eligible heirs

## Manual (device / APK)

- [ ] Install `artifacts/vice-dynasty-release.apk`
- [ ] Portrait only; bottom nav reachable with a thumb on a ~6" phone
- [ ] Play 5+ years, mix activities and “see what the year brings”
- [ ] Spotlight tour: hole around real control, pulse ring, tap target to advance, Skip, Replay from Help
- [ ] Life / Family / City / More tabs; no hollow empty boxes
- [ ] Empire empty: AppBar, path copy, hire CTA or Need \$X more, fronts empty-state plus Open a front shop — no clipped/overlapping text on a small phone
- [ ] Dynasty: drawn tree with connectors, chair, living/dead, circle — no hollow portrait boxes
- [ ] War season: Life and City show WAR SEASON; heat/cash/streets move across threat → escalate → resolve
- [ ] Life shows THIS YEAR ambition and WHEN THE YEAR CLOSED after Next year
- [ ] Empire with crew + a front: Assign watches a shop; Pay / Raise cut / Let go; Income/Risk/Cover; Invest
- [ ] City: Press on open turf, Cool on held turf
- [ ] Family: Sit only one person per year; Sit hidden on others; Gift also only one person per year (independent of Sit)
- [ ] Music / SFX toggles in Settings
- [ ] First launch is dark navy; Settings can switch to paper light and persists
- [ ] Life has no 1-2-3 step bar; Event choices do not list pay/heat/stakes
- [ ] Dynasty / More tile titles show the full word (no clipped “Dynas…”) on a narrow phone
- [ ] Open every More page and return (no dead-end)
- [ ] Settings save to slot 1, kill app, Load game
- [ ] Rewarded retry button appears after a harsh outcome (debug grants if ads fail)
- [ ] Remove Ads debug grant stops interstitial attempts

## Ads / IAP

- [x] Test IDs documented in docs/BUILD.md
- [x] No banner widgets in the tree
- [x] Interstitial gated to generation / prison reasons
- [ ] Real Play Billing product on an internal track

## Content rating

- [x] Event text is narrative fiction, not how-to crime instruction (spot-checked JSON)

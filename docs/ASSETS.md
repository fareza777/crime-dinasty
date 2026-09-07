# Assets — Vice Dynasty 1.9.3

Visual direction: **high-fidelity neo-noir pixel art**. Palette: dark navy `#0B1220`, charcoal `#161D2B`, deep red `#8B1E3F`, gold `#C9A227`, cream `#E8E4D9`. Readable UI, ornate gold chrome, rain-slicked Ravenport. No emoji as primary icons. Do not copy Life Authority or Fate & Fealty.

City: **Ravenport**. Player default: Hart. Rivals: Calderas, Rooke Outfit, House Vex, Marrow Kin. Recurring faces: Silas Crowe, Detective Rhea Vale, Cass Caldera, Mira Keene, Bennett Lang.

Generation: Cursor `GenerateImage` (pixel neo-noir, tone-reference splash + hub panels). Packed by `tool/pack_art.py`, downscaled by `tool/optimize_art.py`. Negative (all prompts): `photorealistic, 3d, emoji, anime eyes, modern UI screenshot, watermark, readable English letters, gore, sexual content, Life Authority, Fate and Fealty`.

## Inventory (shipped)

Count: **116 PNGs** including **20 distinct character portraits** under `assets/images/portraits/` (plus Android mipmaps). 1.3 adds 25 supporting images: menu headers, empty-states, activity tiles, business fronts, tip compass — plus music loop and extra SFX.

| Path | What |
| --- | --- |
| `assets/images/splash.png` | Title / boot rain city + raven-on-ledger crest |
| `assets/images/logo_plate.png` | VICE DYNASTY lockup plate |
| `assets/images/cover.png` | Wide store / load banner |
| `assets/images/title_poster.png` | 3:4 framed title poster (gold lockup over rainy docks) |
| `assets/images/events/panel_rain.png` | Dense rain-dock texture for taller event / header panels |
| `assets/icons/app_icon.png` | 512 store/app mark |
| `assets/icons/foreground.png` / `background.png` | Adaptive layers |
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | Density icons |
| `android/.../mipmap-*-/ic_launcher_foreground.png` | Adaptive foreground |
| `android/.../mipmap-anydpi-v26/ic_launcher.xml` | Adaptive icon |
| `assets/icons/life.png` `family.png` `city.png` `empire.png` `more.png` | Bottom nav |
| `assets/icons/activities.png` `business.png` `relationships.png` `court.png` `legacy.png` `settings.png` | More grid |
| `assets/icons/stat_{health,int,cha,nerve,loyalty,rep,heat,stress,cash}.png` | Stat chips |
| `assets/images/districts/{docks,midtown,old_quarter,glassridge,the_flats,harbor_lights,ironyard,westmere}.png` | Turf cards |
| `assets/images/events/crime_night.png` | Crime night |
| `assets/images/events/family_dinner.png` | Family dinner |
| `assets/images/events/courtroom.png` | Court |
| `assets/images/events/docks_heist.png` | Docks heist |
| `assets/images/events/betrayal.png` | Betrayal |
| `assets/images/events/wedding.png` | Wedding |
| `assets/images/events/prison.png` | Prison |
| `assets/images/events/funeral.png` | Funeral / legacy |
| `assets/images/events/club.png` | Club |
| `assets/images/events/office.png` | Office |
| `assets/images/events/home.png` | Walk-up |
| `assets/images/events/sit.png` | Quiet sit — lamp, rain glass, two cups |
| `assets/images/events/skyline.png` | Skyline |
| `assets/images/events/ledger.png` | Crow ledger |
| `assets/images/events/prosecutor.png` | Vale / court foil |
| `assets/images/events/{street,heist,docks,court,legacy}.png` | Aliases of the above |
| `assets/images/crests/{calderas,rooke,vex,marrow}.png` | Rival crests |
| `assets/images/crew.png` | Crew silhouette |
| `assets/images/dossier_frame.png` | Dossier frame |
| `assets/images/hall.png` | Hall of Legacy |
| `assets/images/empty_chair.png` | Empty chair / heir |
| `assets/images/year_banner.png` | Year chapter banner |
| `assets/images/chrome/{panel,btn_primary,btn_danger,btn_ghost,choice}.png` | UI chrome |
| `assets/images/portraits/*.png` | 20 unique faces (player ×3, sibling, mentor, Vale, Cass, Mira, Ben, matriarch, enforcer, child, spouses, Vex, Nessa, parent, crew, teen, cousin) |
| `assets/images/portrait_0..4.png` | Legacy chips aliased to five of the distinct faces |
| `assets/fonts/Cinzel-*.ttf` | Titles |
| `assets/fonts/DMSans-*.ttf` | UI |
| `assets/images/headers/*.png` | Family, City, Activities, Business, Court, Legacy, Relations, Empire, Settings |
| `assets/images/empty_*.png` | Crew, shop, court, hall, ledger, relations, activities |
| `assets/images/activities/{earn,risk,family,cool}.png` | Side-action tiles |
| `assets/images/fronts/{club,shipping,laundry,construction,restaurant,garage}.png` | Business storefronts |
| `assets/icons/tip_compass.png` | Coach-mark icon |
| `assets/music/ambience.wav` | Original 18s neo-noir loop (generated, shippable) |
| `assets/sfx/*.wav` | tap, success, fail, year, legacy, card, confirm, heat, money |
| `assets/events/*.json` | Narrative |

## Prompts used (regenerate at higher res)

### Splash / logo / cover / icon

```
High-fidelity pixel-art neo-noir splash, vertical rainy American port city at night, dark navy and charcoal Art Deco skyline, gold window lights, one deep-red window, ornate rooftop medallion with a glowing gold raven perched on a bound ledger, fine rain streaks, cinematic, no readable text
```

```
Pixel-art gold VICE DYNASTY logo lockup plate, ornate filigree, raven on a book, dark navy, no extra letters besides implied crest, premium
```

```
Neo-noir pixel-art wide banner of a rainy port city at night, dark navy and charcoal, gold street reflections, deep red neon in the distance, cranes and brick warehouses, cinematic, no logos
```

```
Modern pixel-art app icon, neo-noir, dark navy, gold raven on a closed ledger, rainy port skyline, deep-red window, square, padding for Android adaptive icon safe zone, no text
```

### Nav / More / stats

```
Square 64px-logic pixel-art game icon on navy: [open leather dossier with red wax seal | family tree gold lines | rain city map with one red district | gold empire building | gold diamond more glyph | gavel | hall of statues | gears ledger | whiskey-and-gun desk | handshake]. Gold rim light, no letters, neo-noir
```

```
Tiny pixel-art resource icon, gold glow, navy field, [heart | lamp/brain | mask/charm | blade/nerve | clasped hands | laurel/rep | siren/heat | cracked glass/stress | cash clip]. No emoji, no text
```

### Districts (8)

```
Cinematic pixel-art night view of Ravenport district [The Docks cranes and crates | Midtown glass lawyers | Old Quarter brick neon saints | Glassridge hill money rain | The Flats row houses | Harbor Lights clubs and ferries | Ironyard quiet foundries | Westmere private gates], rain-slicked, navy charcoal gold deep-red window, no street names
```

### Event headers (14)

```
Pixel-art neo-noir event header, 16:9, [crime alley wet cobble vintage car | family boardroom mahogany portrait | courtroom eagle lanterns | docks heist crates fog | betrayal red window | wedding rain gold | prison corridor | funeral hall of statues | jazz club booth | midtown office rain on glass | walk-up kitchen cheap cake | skyline bridge | leather ledger gold crest | detective diner photograph], chiaroscuro, no readable English
```

### Crests / crew / hall / chrome / portraits

```
Pixel-art heraldic crest on navy: [gold volcano caldera over waves | deep-red rook chess piece | thin geometric gold V | abstracted marrow-bone]. Ornate gold frame, no letters
```

```
Pixel-art crew silhouettes in raincoats under a dock lamp, gold rim, navy, no faces readable
```

```
Pixel-art dossier frame, gold filigree, red wax, empty center for a portrait, navy
```

```
Pixel-art Hall of Legacy: long pillared corridor, white statues, plush red carpet, gold frames, navy, empty chair at far portrait
```

```
UI chrome for neo-noir pixel game: empty dark navy rectangle, ornate double gold filigree border, corner scrollwork, tiny deep-red diamonds, no text
```

```
Pixel-art bust portraits, 64x64 logic, neo-noir gold rim, navy: older mentor in raincoat; woman detective; young rival heir with gold jewelry; Harbor Lights woman; Glassridge man in a dark suit. No text
```

## Audio

Keep `assets/sfx/*.wav` original. Replace with 80–200ms cues of the same names if you re-score. Do not rip commercial tracks.

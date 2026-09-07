# Build

Vice Dynasty is a Flutter Android app. Package / applicationId: `com.vicedynasty.life`.

## Prerequisites

- Flutter 3.47+ (stable)
- Android SDK (platform 35+, build-tools 35+)
- JDK 17+ (21 works)

```bash
flutter doctor
flutter pub get
```

## Run

```bash
# Android device / emulator, portrait
flutter run --release

# Web preview (ads/IAP are stubbed)
flutter run -d chrome --web-port 43151
```

## APK (sideload)

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

This repo copies a playable APK to:

`artifacts/vice-dynasty-release.apk`

The release build currently signs with the **debug keystore** so `flutter run --release` and sideload installs work. For Play Store, create an upload keystore and point `android/app/build.gradle.kts` `signingConfigs.release` at it. Do not commit the keystore or passwords.

## Android App Bundle (Play)

```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

Upload the AAB in Play Console. The Gradle file already uses Flutter's `versionName` / `versionCode` from `pubspec.yaml` (`1.9.3+16`). Bump `version:` before each store push. A real Play upload keystore is still a 2.0 / store-setup item — this repo ships debug-signed sideload builds.

This worker can produce a **debug-signed** AAB the same way it signs the sideload APK (`signingConfigs.release` points at the debug keystore). Play Console **internal testing** will accept that only as a stopgap. For production:

1. Create an upload keystore (`keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`).
2. Add `android/key.properties` (gitignored) with `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
3. Point `signingConfigs.release` at those values.
4. Rebuild `flutter build appbundle --release` and upload that AAB.

Do not commit the keystore or passwords. Keep using the debug-signed APK for sideload QA.

Release APKs include **armeabi-v7a**, **arm64-v8a**, and **x86_64**. R8 minify is **off** so Play/Ads classes cannot be stripped on a sideload build. `MobileAdsInitProvider` is removed from the manifest so AdMob cannot crash the process before the first frame on devices without Play Services. Ads and IAP init after the first frame and fail soft.

## AdMob — test IDs now, production later

Development uses **official Google test IDs** (safe for debug devices):

| Slot | Test ID |
| --- | --- |
| App | `ca-app-pub-3940256099942544~3347511713` |
| Rewarded | `ca-app-pub-3940256099942544/5224354917` |
| Interstitial | `ca-app-pub-3940256099942544/1033173712` |

The Android manifest `APPLICATION_ID` meta-data is the test app id. **There are no banner ads.**

Rewarded ads: retry the last failed decision, or a small “bonus whisper” extra chance. Interstitials fire only at **generation end** or **major jail entry**, and are throttled (about every 4 in-game years and 8 real minutes).

Swap to production:

1. Create an AdMob Android app and ad units (rewarded + interstitial only).
2. Replace the manifest value:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy"/>
```

3. Build with dart-defines (picked up by `AdsConfig`):

```bash
flutter build appbundle --release \
  --dart-define=ADMOB_APP_ID=ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy \
  --dart-define=ADMOB_REWARDED_ID=ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz \
  --dart-define=ADMOB_INTERSTITIAL_ID=ca-app-pub-xxxxxxxxxxxxxxxx/wwwwwwwwww
```

You must still put the **app** id in the manifest; dart-defines cover the unit ids used at runtime.

On sideload / emulators without Play services, rewarded calls fall back in **debug** so the retry loop stays testable. Release builds without a filled ad do not grant the reward.

## Remove Ads IAP

- Product id: `com.vicedynasty.life.remove_ads`
- Type: one-time managed product (Play Billing)
- Create it in Play Console → monetize → in-app products
- The app queries that id via `in_app_purchase`. If the catalog is empty (sideload), Settings exposes **Debug: grant remove ads** so QA can verify the ads-removed path. Remove or hide that button before a production store listing if you do not want it in the shipped binary (`kDebugMode` already gates the silent grant inside `buyRemoveAds`; the settings button is always visible for this development build — strip it when you ship store-signed).

License testers: add Gmail accounts in Play Console, install from an internal track, purchase with a test card.

## Content events

JSON lives in `assets/events/`. `manifest.json` lists the files. Add an object, bump weight, set `requires` flags. The engine ignores unknown fields.

## Tests

```bash
flutter test
flutter analyze
```

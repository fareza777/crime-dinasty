# Keep Flutter / Play / Ads classes if minify is re-enabled later.
# Release currently ships with minifyEnabled=false; these rules are a safety net.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.play.** { *; }
-keep class com.android.billingclient.** { *; }
-keep class xyz.luan.audioplayers.** { *; }
-keep class com.ryanheise.** { *; }

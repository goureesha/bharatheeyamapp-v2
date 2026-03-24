# Flutter/Dart ProGuard rules
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google APIs (Sheets, Calendar, etc.)
-keep class com.google.api.** { *; }
-dontwarn com.google.api.**

# HTTP client
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Gson
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

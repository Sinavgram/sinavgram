# Jenerik imzaların (TypeToken vb.) korunmasını sağlar
-keepattributes Signature
-keepattributes *Annotation*

# Gson ve TypeToken kuralları
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

-keep class com.aboutyou.dart_signin_with_apple.** { *; }
-keep interface com.aboutyou.dart_signin_with_apple.** { *; }

# Flutter Local Notifications eklentisinin sınıflarını korur
-keep class com.dexterous.flutterlocalnotifications.** { *; }
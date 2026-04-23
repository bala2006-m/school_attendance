# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dart/Flutter runtime
-keep class dart.** { *; }
-keep class com.google.dart.** { *; }

# Keep all model classes and POJOs
-keepclasseswithmembers class * {
    native <methods>;
}

-keepclasseswithmembers class * {
    *** *_preserveStaticInitializers();
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Image Picker
-keep class com.example.image_picker_android.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }

# Flutter deferred components (keep even though Play Core is missing)
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$* { *; }

# Allow missing Play Core classes referenced by Flutter (deferred components disabled)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# PDF & Printing
-keep class io.flutter.plugins.printing.** { *; }

# Shared Preferences
-keep class com.example.shared_preferences_android.** { *; }

# Location services
-keep class com.baseflow.geolocator.** { *; }

# Network libraries
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**

# JSON parsing
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# HTTP client
-keep class org.apache.http.** { *; }
-dontwarn org.apache.http.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Kotlin
-keep class kotlin.** { *; }
-keep interface kotlin.** { *; }
-dontwarn kotlin.**

# Lambda expressions
-dontwarn java.lang.invoke.*

# General exceptions
-dontwarn java.lang.management.**
-dontwarn javax.annotation.**

# Keep BuildConfig
-keep class **.BuildConfig { *; }

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}
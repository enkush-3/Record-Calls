# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Record Call Native Classes
-keep class mn.callrecorder.record_calls.** { *; }
-keepclassmembers class mn.callrecorder.record_calls.** { *; }

# AndroidX Core & Lifecycle
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.app.** { *; }

# Scoped Storage & SQLite
-keep class com.tekartik.sqflite.** { *; }

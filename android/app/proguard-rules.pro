# R8 ProGuard Rules - tells R8 what to keep without removing/renaming
# FFmpeg Kit
-keep class com.antonkarpenko.ffmpegkit.** { *; }
#Native library the FFmpeg  kit use
-keep class com.arthenica.** { *; }

# Don't warn about missing classes
-dontwarn com.antonkarpenko.ffmpegkit.**
-dontwarn com.arthenica.**
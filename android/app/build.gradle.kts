plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

// Google Maps key for the manifest's com.google.android.geo.API_KEY. Never
// committed: read from the Flutter .env at the project root (the same file
// the Dart side loads), then local.properties, then the environment. An
// absent key leaves the placeholder empty so the build still succeeds; only
// the map fails to render.
val dotEnv = Properties().apply {
    val f = rootProject.file("../.env")
    if (f.exists()) f.reader(Charsets.UTF_8).use { load(it) }
}
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.reader(Charsets.UTF_8).use { load(it) }
}
fun secretValue(vararg names: String): String {
    for (name in names) {
        val raw = dotEnv.getProperty(name) ?: localProps.getProperty(name) ?: System.getenv(name)
        // .env values may be quoted.
        val value = raw?.trim()?.trim('"', '\'') ?: ""
        if (value.isNotEmpty()) return value
    }
    logger.warn("No Google Maps key found for ${names.joinToString(" / ")}; the map will not render.")
    return ""
}

android {
    namespace = "app.tiler.tiler_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.tiler.tiler_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AppAuth redirect scheme for the Microsoft (Entra) native sign-in
        // (flutter_appauth). Must match `microsoftRedirectScheme` in lib/constants.dart
        // and the "Mobile and desktop applications" redirect URI on the Entra app.
        manifestPlaceholders["appAuthRedirectScheme"] = "msal6d9f8ba1-1980-4a28-9516-7a8af2227bd2"
        manifestPlaceholders["googleMapsApiKey"] = secretValue("GOOGLE_MAPS_API_KEY")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

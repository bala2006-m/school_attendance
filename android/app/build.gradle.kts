plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
        import java.io.FileInputStream

// Load keystore
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.ramchin_smart_school"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13113456"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.demo.ramchin_smart_school"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
        manifestPlaceholders.putAll(mapOf("usesCleartextTraffic" to "true"))
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
//    signingConfigs {
//        release {
//            storeFile file("C:\\School Attendance\\school_attendance\\android\\app\\my-release-key.keystore")
//            storePassword "Ramchin@123"
//            keyAlias "my-key-alias"
//            keyPassword "Ramchin@123"
//        }
//    }
    buildTypes {
        release {
            // Uses the "release" signing config (must be defined in signingConfigs block)
            signingConfig = signingConfigs.getByName("release")

            // Code shrinking & obfuscation (ENABLED for Play Store)
            isMinifyEnabled = true
            isShrinkResources = true

            // ProGuard/R8 rules files
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Removed Google Play Core 1.10.0 - incompatible with targetSdkVersion 34
    // Deferred components are disabled in gradle.properties
}

flutter {
    source = "../.."
}

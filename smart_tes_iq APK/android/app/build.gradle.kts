import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.cellanomadigital.smart_tes_iq"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.cellanomadigital.smart_tes_iq"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile"))
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.activity:activity-ktx:1.9.3")
    implementation("com.android.billingclient:billing:9.0.0")

    // =========================================================================
    // GOOGLE ADMOB MEDIATION ADAPTERS (TRIO: ADMOB + UNITY ADS + LIFTOFF/VUNGLE)
    // =========================================================================
    // 1. Unity Ads (Game ID: 800399256 | BP_Rewarded_Android & BP_Banner_Android)
    implementation("com.google.ads.mediation:unity:4.12.5.0")
    // 2. Liftoff Monetize / Vungle (App ID: 6ad053875bdb53e5e0ed6499)
    implementation("com.google.ads.mediation:vungle:7.4.2.0")
}

// Perbaikan Obfuscation DEX Play Console:
// AAR vungle-ads:7.4.2 membawa aturan `-keep class com.google.android.gms.** { *; }`
// yang mematikan obfuscation R8 pada >10.000 class internal Google Play Services
// sehingga skor obfuscation turun ke 20% (di bawah batas minimum 25% Play Console).
tasks.matching { it.name.startsWith("minify") && it.name.endsWith("WithR8") }.configureEach {
    doFirst {
        inputs.files.forEach { file ->
            if (file.exists() && file.name == "proguard.txt" && file.path.contains("vungle-ads")) {
                val content = file.readText()
                if (content.contains("-keep class com.google.android.gms.**")) {
                    val patched = content.replace(
                        "-keep class com.google.android.gms.** { *; }",
                        "-keep class com.google.android.gms.ads.identifier.** { *; }\n" +
                            "-keep class com.google.android.gms.appset.** { *; }\n" +
                            "-keep class com.google.android.gms.common.GoogleApiAvailabilityLight { *; }"
                    )
                    file.writeText(patched)
                }
            }
        }
    }
}
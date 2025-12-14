plugins {
    id("com.android.application")
    id("kotlin-android")
    //id("com.google.gms.google-services") version "4.4.0" apply false
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.profile_managemenr"
    compileSdk = flutter.compileSdkVersion

    ndkVersion = "28.2.13676358"

    defaultConfig {
        applicationId = "com.example.profile_managemenr"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ❌ REMOVE this block:
    // applicationVariants.all { ... }
    // Let Flutter handle APK output path automatically
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.0")

    // Firebase
    implementation(platform("com.google.firebase:firebase-bom:32.8.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")
}

flutter {
    source = "../.."
}

apply(plugin = "com.google.gms.google-sevices")
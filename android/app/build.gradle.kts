plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.login_sqlite_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.login_sqlite_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Kotlin stdlib
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.10")

    // Desugar necesario para flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")

    // Firebase BoM (gestiona versiones automáticamente)
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))

    // Dependencias de Firebase
    implementation("com.google.firebase:firebase-analytics")
    // Agrega aquí más Firebase como auth, messaging, firestore, etc.
}

flutter {
    source = "../.."
}

// ✅ Aplica el plugin de Google Services aquí, al final
apply(plugin = "com.google.gms.google-services")

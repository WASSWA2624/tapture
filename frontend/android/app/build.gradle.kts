plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.tapture.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.tapture.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Distinct application ids and labels so a development install sits
    // alongside a production one (dev-plan 02-foundation/019).
    flavorDimensions += "flavor"
    productFlavors {
        create("dev") {
            dimension = "flavor"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Tapture Dev")
        }
        create("prod") {
            dimension = "flavor"
            resValue("string", "app_name", "Tapture")
        }
    }

    buildTypes {
        release {
            // Debug keys keep `flutter run --release` working until dev-plan task 278
            // introduces the real signing configuration.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

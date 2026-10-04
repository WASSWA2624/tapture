import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystoreFile = rootProject.file("key.properties")
if (keystoreFile.exists()) {
    keystoreFile.inputStream().use { stream -> keystoreProperties.load(stream) }
}

fun signingValue(property: String, envName: String): String {
    val fromEnv = System.getenv(envName)
    if (!fromEnv.isNullOrBlank()) return fromEnv
    return keystoreProperties.getProperty(property) ?: ""
}

val releaseStore = signingValue("storeFile", "TAPTURE_KEYSTORE")
val releaseStorePassword = signingValue("storePassword", "TAPTURE_STORE_PASSWORD")
val releaseAlias = signingValue("keyAlias", "TAPTURE_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "TAPTURE_KEY_PASSWORD")
val hasReleaseKey = releaseStore.isNotBlank() &&
    releaseStorePassword.isNotBlank() &&
    releaseAlias.isNotBlank() &&
    releaseKeyPassword.isNotBlank()

android {
    namespace = "com.tapture.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
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

    // Speech models (assets/speech/*.bin) stay uncompressed in the APK, so
    // extractFlutterAsset streams them out without inflating (task 109).
    androidResources {
        noCompress += "bin"
    }

    // AGP 9 turns resValues off by default. The flavour labels below use it.
    buildFeatures {
        resValues = true
    }

    // Distinct application ids and labels so a development install sits
    // alongside a production one (dev-plan task 002).
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

    signingConfigs {
        create("release") {
            if (hasReleaseKey) {
                storeFile = file(releaseStore)
                storePassword = releaseStorePassword
                keyAlias = releaseAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            // A release keystore signs the store build. Without one, the
            // local deploy script still produces an installable APK.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

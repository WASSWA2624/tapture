plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = java.util.Properties()
val keystoreFile = rootProject.file("key.properties")
if (keystoreFile.exists()) {
    keystoreFile.inputStream().use { keystoreProperties.load(it) }
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

    // AGP 9 turns resValues off by default. The flavour labels below use it.
    buildFeatures {
        resValues = true
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
            if (hasReleaseKey) {
                signingConfig = signingConfigs.getByName("release")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    splits {
        abi {
            isEnable = true
            reset()
            include("armeabi-v7a", "arm64-v8a", "x86_64")
            isUniversalApk = false
        }
    }
}

tasks.configureEach {
    if (name.contains("Release") && !hasReleaseKey) {
        doFirst {
            throw GradleException(
                "Missing signing key. Set TAPTURE_KEYSTORE, TAPTURE_STORE_PASSWORD, " +
                    "TAPTURE_KEY_ALIAS and TAPTURE_KEY_PASSWORD, or android/key.properties.",
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

import java.util.Properties
import java.io.FileInputStream

// ── Release signing material ────────────────────────────────────────────────
// Loaded from android/key.properties (git-ignored) for local release builds, or
// from environment variables in CI (docs/cl_cd_deployment.md "Required GitHub
// Secrets"). Passwords are never hardcoded here.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystoreFile = keystorePropertiesFile.exists()
if (hasKeystoreFile) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// CI path: the workflow decodes ANDROID_KEYSTORE into a file and exports the
// passwords. Takes precedence over key.properties when present.
val envStoreFile: String? = System.getenv("ANDROID_KEYSTORE_PATH")
val hasEnvSigning = !envStoreFile.isNullOrBlank()

// True only when we can actually produce a signed release build. When false,
// release falls back to debug signing so `flutter build apk --release` still
// succeeds on a clean checkout instead of failing on a null storeFile.
val canSignRelease = hasEnvSigning || hasKeystoreFile

// ── Environment config ──────────────────────────────────────────────────────
// The Google Maps key is injected as a manifest placeholder rather than being
// committed in AndroidManifest.xml (docs/SECURITY.md §9). Source order:
// GOOGLE_MAPS_ANDROID_KEY env var (CI) → .env file (local dev) → empty.
val dotenv = Properties()
val dotenvFile = rootProject.file("../.env")
if (dotenvFile.exists()) {
    dotenvFile.inputStream().use { dotenv.load(it) }
}
val googleMapsApiKey: String =
    System.getenv("GOOGLE_MAPS_ANDROID_KEY")
        ?: dotenv.getProperty("GOOGLE_MAPS_ANDROID_KEY")
        ?: ""

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.isigroup.steelsales"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Permanent for the life of the Play listing — do not change after the
        // first upload.
        applicationId = "com.isigroup.steelsales"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = googleMapsApiKey
    }

    signingConfigs {
        if (canSignRelease) {
            create("release") {
                if (hasEnvSigning) {
                    storeFile = file(envStoreFile!!)
                    storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                    keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                    keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
                } else {
                    storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                    storePassword = keystoreProperties.getProperty("storePassword")
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                }
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }

        release {
            // R8: strip unused compiled code and unused resources.
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )

            signingConfig =
                if (canSignRelease) {
                    signingConfigs.getByName("release")
                } else {
                    // Debug-signed: installable for a local smoke test, but NOT
                    // uploadable to Play. CI must supply the real keystore.
                    logger.warn(
                        "WARNING: no release keystore found (key.properties or " +
                            "ANDROID_KEYSTORE_PATH). Falling back to debug signing — " +
                            "this artifact cannot be published.",
                    )
                    signingConfigs.getByName("debug")
                }
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

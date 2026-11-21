import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de l'APK livré (D10.1, guide docs/LIVRAISON.md) : JAMAIS dans le dépôt.
// 1. Sur le PC de Loick : android/key.properties (ignoré par git) ;
// 2. En CI : variables ELECPAY_KEYSTORE_FILE, ELECPAY_KEYSTORE_PASSWORD, ELECPAY_KEY_ALIAS,
//    ELECPAY_KEY_PASSWORD (secrets GitHub) ;
// 3. Sinon : clé de débogage d'Android (refusée par `apk_check --signature=release`).
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
fun signingValue(property: String, variable: String): String? =
    keyProperties.getProperty(property) ?: System.getenv(variable)
val releaseStoreFile = signingValue("storeFile", "ELECPAY_KEYSTORE_FILE")

android {
    namespace = "cg.elecpay.client"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Identifiant définitif (Play Store), validé par Loick le 15/11/2026.
        applicationId = "cg.elecpay.client"
        // Android 7 (API 24) au minimum, validé par Loick.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = file(releaseStoreFile)
                storePassword = signingValue("storePassword", "ELECPAY_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ELECPAY_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ELECPAY_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseStoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("ElecPay : aucune clé de l'APK livré, APK release signé avec la clé de DÉBOGAGE.")
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

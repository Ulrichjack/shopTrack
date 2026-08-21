import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingSecret(propertyName: String, filePropertyName: String): String {
    val directValue = keystoreProperties.getProperty(propertyName)
    if (!directValue.isNullOrBlank()) return directValue

    val secretFile = keystoreProperties.getProperty(filePropertyName)
        ?: error("Propriété $propertyName ou $filePropertyName manquante")
    return rootProject.file(secretFile).readText().trim()
}

android {
    namespace = "cm.shoptrack.shoptrack"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "cm.shoptrack.shoptrack"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = signingSecret("keyPassword", "keyPasswordFile")
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = signingSecret(
                    "storePassword",
                    "storePasswordFile",
                )
            }
        }
    }

    buildTypes {
        release {
            // Une version publiée ne doit jamais être signée avec la clé debug.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
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

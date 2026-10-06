import java.util.Properties

plugins {
    id("com.android.application")
    // Lee google-services.json para que los SDK de Firebase (firebase_core,
    // firebase_auth, cloud_firestore) tomen la config del proyecto real.
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─── Signing de release ──────────────────────────────────────────────────────
// Las contraseñas se leen de android/key.properties (ignorado por Git).
// El keystore está en android/app/floply-upload.jks (ignorado por Git).
// NUNCA poner contraseñas en este archivo.
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(keyPropertiesFile.inputStream())
}

android {
    namespace = "com.floply.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        create("release") {
            keyAlias      = keyProperties["keyAlias"]      as String
            keyPassword   = keyProperties["keyPassword"]   as String
            storeFile     = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    defaultConfig {
        applicationId = "com.floply.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
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

// integration_test is a dev_dependency whose Android class is absent from the release
// classpath. The Flutter Gradle plugin regenerates GeneratedPluginRegistrant.java on
// every build (including it), so we strip that block right before javac runs.
tasks.whenTaskAdded {
    if (name == "compileReleaseJavaWithJavac") {
        doFirst {
            val registrant = file("src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java")
            if (registrant.exists()) {
                var content = registrant.readText()
                val marker = "dev.flutter.plugins.integration_test.IntegrationTestPlugin"
                val markerPos = content.indexOf(marker)
                if (markerPos != -1) {
                    val tryStart = content.lastIndexOf("    try {", markerPos)
                    if (tryStart != -1) {
                        val catchPos  = content.indexOf("    } catch", markerPos)
                        val closePos  = content.indexOf("    }", catchPos + 1)
                        val blockEnd  = content.indexOf('\n', closePos) + 1
                        content = content.substring(0, tryStart) + content.substring(blockEnd)
                        registrant.writeText(content)
                    }
                }
            }
        }
    }
}

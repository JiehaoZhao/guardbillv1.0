plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.guard_bill"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "30.0.14904198"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.guard_bill"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

// 🛡️ Guard Bill 路径自动修正守卫
// 每次 Gradle 完成 assembleDebug 任务后，自动将 APK 实体文件同步复制到 Flutter 预期的根目录
tasks.whenTaskAdded {
    if (name == "assembleDebug" || name == "assembleRelease") {
        doLast {
            val originFile = file("${project.layout.buildDirectory.get()}/outputs/flutter-apk/app-debug.apk")
            val targetDir = file("${rootProject.projectDir}/../build/app/outputs/flutter-apk/")

            if (originFile.exists()) {
                // 如果 Flutter 预期的根目录不存在，自动创建它
                if (!targetDir.exists()) {
                    targetDir.mkdirs()
                }
                // 执行物理复制，强行打通时空隧道
                originFile.copyTo(file("${targetDir.path}/app-debug.apk"), overwrite = true)
                println("====== [Guard Bill 自动修复] 已成功将 APK 同步至 Flutter 预期路径 ======")
            }
        }
    }
}
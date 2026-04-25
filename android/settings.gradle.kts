pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }
    val flutterToolsGradleDir =
        java.io.File(flutterSdkPath)
            .resolve("packages")
            .resolve("flutter_tools")
            .resolve("gradle")
    require(flutterToolsGradleDir.exists()) {
        "Flutter tools gradle directory not found: ${flutterToolsGradleDir.absolutePath}"
    }
    includeBuild(flutterToolsGradleDir.absolutePath)
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}
include(":app")

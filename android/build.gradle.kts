import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

group = "com.example.zebra_printing_plugin"
version = "1.0-SNAPSHOT"

buildscript {
    val kotlinVersion = "1.8.22"
    
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.7.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

apply(plugin = "com.android.library")
apply(plugin = "kotlin-android")

android {
    namespace = "com.example.zebra_printing_plugin"
    compileSdk = 35

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    sourceSets {
        named("main") {
            java.srcDirs("src/main/kotlin")
        }
        named("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 21
    }

    testOptions {
        unitTests.all {
            it.useJUnitPlatform()

            it.testLogging {
                events("passed", "skipped", "failed", "standardOut", "standardError")
                showStandardStreams = true
            }
        }
    }
}

// Configure Kotlin compilation options
tasks.withType<KotlinCompile>().configureEach {
    kotlinOptions {
        jvmTarget = "11"
    }
}

project.dependencies {
    // Use local JAR file for Zebra SDK
    add("implementation", files("libs/ZSDK_ANDROID_API.jar"))
    
    // Coroutines for async operations
    add("implementation", "org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    add("testImplementation", "org.jetbrains.kotlin:kotlin-test")
    add("testImplementation", "org.mockito:mockito-core:5.0.0")
}

// Type-safe accessor for the android extension
fun android(configure: com.android.build.gradle.LibraryExtension.() -> Unit) {
    project.extensions.configure("android", configure)
}

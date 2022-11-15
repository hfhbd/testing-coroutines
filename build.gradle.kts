import org.jetbrains.kotlin.gradle.plugin.mpp.*
import org.jetbrains.kotlin.gradle.plugin.mpp.apple.*

plugins {
    kotlin("multiplatform") version "1.8.0-Beta"
    id("app.cash.licensee") version "1.6.0"
}

repositories {
    mavenCentral()
}

kotlin {
    jvm()

    val xcf = XCFramework()
    fun KotlinNativeTarget.f() {
        binaries {
            framework {
                export("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
                xcf.add(this)
            }
        }
    }
    iosArm64 {
        f()
    }
    iosSimulatorArm64 {
        f()
    }
    macosArm64 {
        f()
    }
    macosX64 {
        f()
    }

    sourceSets {
        commonMain {
            dependencies {
                api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
            }
        }
        commonTest {
            dependencies {
                implementation(kotlin("test"))
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.4")
            }
        }
    }
}

licensee {
    allow("Apache-2.0")
}

val assembleXCFramework by tasks

tasks.register("generateSPM") {
    dependsOn(assembleXCFramework)

    doLast {
        (File(buildDir, "XCFrameworks").listFiles() ?: emptyArray()).forEach {
            val output = File(it, "Package.swift")
            println(output.path)
            if (!output.exists()) {
                output.createNewFile()
            }
            output.writeText(
                """
                    // swift-tools-version:5.5

                    import PackageDescription

                    let package = Package(
                        name: "testing_coroutines",
                        platforms: [.iOS(.v13), .macOS(.v11)],
                        products: [
                            .library(
                                name: "testing_coroutines",
                                targets: ["testing_coroutines"]),
                        ],
                        targets: [
                            .binaryTarget(
                                name: "testing_coroutines",
                                path: "testing_coroutines.xcframework"
                            )
                        ]
                    )
                """.trimIndent()
            )
        }
    }
}

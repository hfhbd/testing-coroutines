import org.jetbrains.kotlin.gradle.plugin.mpp.apple.*

plugins {
    // Apache 2, https://github.com/JetBrains/kotlin/releases/latest
    kotlin("multiplatform") version "1.6.20-RC"
}

repositories {
    mavenCentral()
}

kotlin {
    jvm()

    val xcf = XCFramework()
    iosArm64 {
        binaries {
            framework {
                baseName = "shared"
                export("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0")
                xcf.add(this)
            }
        }
    }
    iosSimulatorArm64 {
        binaries {
            framework {
                baseName = "shared"
                export("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0")
                xcf.add(this)
            }
        }
    }

    sourceSets {
        commonMain {
            dependencies {
                api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0")
            }
        }
        commonTest {
            dependencies {
                implementation(kotlin("test"))
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.0")
            }
        }
    }
}

tasks.register("generateSPM") {
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
                        name: "shared",
                        platforms: [.iOS(.v13)],
                        products: [
                            .library(
                                name: "shared",
                                targets: ["shared"]),
                        ],
                        targets: [
                            .binaryTarget(
                                name: "shared",
                                path: "testing_coroutines.xcframework"
                            )
                        ]
                    )
                """.trimIndent()
            )
        }
    }
}

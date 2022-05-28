import org.jetbrains.kotlin.gradle.plugin.mpp.apple.*

plugins {
    // Apache 2, https://github.com/JetBrains/kotlin/releases/latest
    kotlin("multiplatform") version "1.6.21"
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
                export("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.2")
                xcf.add(this)
            }
        }
    }
    iosSimulatorArm64 {
        binaries {
            framework {
                export("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.2")
                xcf.add(this)
            }
        }
    }

    sourceSets {
        commonMain {
            dependencies {
                api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.2")
            }
        }
        commonTest {
            dependencies {
                implementation(kotlin("test"))
                implementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.6.2")
            }
        }
    }
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
                    // swift-tools-version:5.6

                    import PackageDescription

                    let package = Package(
                        name: "testing_coroutines",
                        platforms: [.iOS(.v13)],
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

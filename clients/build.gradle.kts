import org.jetbrains.kotlin.gradle.plugin.mpp.apple.*

plugins {
    kotlin("multiplatform")
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

        val iosArm64Main by getting {
            dependencies {
            }
        }

        val iosSimulatorArm64Main by getting {
            dependsOn(iosArm64Main)
        }
    }
}

tasks {
    val assembleXCFramework by tasks

    val generateSPM by creating {
        dependsOn(assembleXCFramework)
        doLast {
            (File(buildDir, "XCFrameworks").listFiles() ?: emptyArray())
                .forEach {
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
                                path: "clients.xcframework"
                            )
                        ]
                    )
                """.trimIndent()
                    )
                }
        }
    }
}

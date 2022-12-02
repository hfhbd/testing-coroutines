import org.jetbrains.kotlin.gradle.plugin.mpp.*
import org.jetbrains.kotlin.gradle.plugin.mpp.apple.*

plugins {
    kotlin("multiplatform")
}

repositories {
    mavenCentral()
}

kotlin {
    jvm()

    val xcf = XCFramework()
    fun KotlinNativeTarget.xcFramework() {
        binaries {
            framework {
                export("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
                xcf.add(this)
            }
        }
    }

    iosArm64 { xcFramework() }
    iosSimulatorArm64 { xcFramework() }
    iosX64 { xcFramework() }

    tvosArm64 { xcFramework() }
    tvosSimulatorArm64 { xcFramework() }
    tvosX64 { xcFramework() }

    watchosArm32 { xcFramework() }
    watchosArm64 { xcFramework() }
    // watchosDeviceArm64 { xcFramework() }
    watchosSimulatorArm64 { xcFramework() }
    watchosX86 { xcFramework() }
    watchosX64 { xcFramework() }

    macosArm64 { xcFramework() }
    macosX64 { xcFramework() }

    sourceSets {
        commonMain {
            dependencies {
                api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
            }
        }
    }
}

val assembleXCFramework by tasks

tasks.register("generateSPM") {
    dependsOn(assembleXCFramework)

    val frameworks = project.layout.buildDirectory.dir("XCFrameworks").map { it.asFile.listFiles() }

    doLast {
        frameworks.get().forEach {
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
                        name: "testCounter",
                        platforms: [.iOS(.v13), .macOS(.v10_15), .tvOS(.v13), .watchOS(.v6)],
                        products: [
                            .library(
                                name: "testCounter",
                                targets: ["testCounter"]),
                        ],
                        targets: [
                            .binaryTarget(
                                name: "testCounter",
                                path: "testCounter.xcframework"
                            )
                        ]
                    )
                """.trimIndent()
            )
        }
    }
}

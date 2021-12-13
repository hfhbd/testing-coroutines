import org.jetbrains.kotlin.gradle.plugin.mpp.apple.*

plugins {
    kotlin("multiplatform")
}

kotlin {
    val xcf = XCFramework()
    iosArm64 {
        binaries {
            framework {
                baseName = "shared"
                export("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0-RC2")
                xcf.add(this)
            }
        }
    }
    iosSimulatorArm64 {
        binaries {
            framework {
                baseName = "shared"
                export("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0-RC2")
                xcf.add(this)
            }
        }
    }

    sourceSets {
        commonMain {
            dependencies {
                api("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.0-RC")
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

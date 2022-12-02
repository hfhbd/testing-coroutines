# testing-coroutines

Testing `kotlinx.coroutines.flow.Flow` on all Apple targets with Swift async/await.

## Result

Collecting on MainThread is still required up to Kotlin 1.7.20. Swift 5.5 async/await, the `@MainActor` annotation and
the new `AsyncStream` allows comfortable usage.

With Kotlin 1.7.20 and `kotlin.native.binary.objcExportSuspendFunctionLaunchThreadRestriction=none`, using the
MainThread is not required anymore.

## Building

1. `./gradlew assembleXCFramework generateSPM` (This takes a while :)
2. `swift build` and `swift test`

To run test sample app, open the `iosApp` Xcode project in the `iosApp` folder with Xcode.

# testing-coroutines

Testing `Flow.collect` on iOS with new memory manager.

## Result

Collecting on MainThread is still required up to Kotlin 1.7.20. Swift 5.5 async/await and the new `AsyncStream` allows comfortable usage.

With Kotlin 1.7.20 and `kotlin.native.binary.objcExportSuspendFunctionLaunchThreadRestriction=none`, using the MainThread is not required anymore.

## Building

1. `./gradlew assembleXCFramework generateSPM`
2. Open `Package.swift` in iOS folder with Xcode
3. Run the ios tests

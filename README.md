# testing-coroutines
Testing `Flow.collect` on iOS with new memory manager.

## Result
Collecting on MainThread is still required. Swift 5.5 async/await and the new `AsyncStream` allows comfortable usage. 

## Building
1. `./gradlew assembleXCFramework generateSPM`
2. Open `Package.swift` in iOS folder with Xcode
3. Run the tests

import XCTest
@testable import ios
import shared
import Combine

class iosSPMTests: XCTestCase {
    @MainActor
    func testKotlinSuspendFunction1() async throws {
        let action: KotlinSuspendFunction0 = AsyncSuspendFunction0<Void> {
            
        }
        try await FlowsKt.runOnMain(action: action)
        /*
         suspend fun<T> runOnMain(action: suspend CoroutineScope.() -> T): T = withContext(Dispatchers.Main) {
         action()
         }
         */
    }

    @MainActor
    func testWithContext() async throws {
        let action: KotlinSuspendFunction1 = AsyncSuspendFunction1<CoroutineScope, Void> { _ in
            
        }
        try await Builders_commonKt.withContext(context: Dispatchers.shared.Main, block: action)
        /*
         equivalent to:
         withContext(Dispatchers.Main) {
             action()
         }
         */
    }

    @MainActor
    func testFlowToAsyncStream() async throws {
        let expectation = [1, 2, 3]
        let results = try await FlowsKt.flowFrom(expectation).stream(Int.self).collect()
        XCTAssertEqual(expectation, results)
    }

    @MainActor
    func testCancelling() async {
        let expectation = [1, 2, 3]
        let stream = FlowsKt.flowFrom(expectation).stream(Int.self)
        let t = Task { () -> [Int] in
            try await Task.sleep(nanoseconds: 3_000_000)
            return try await stream.collect()
        }
        t.cancel()
        let value = (try? await t.value) ?? []
        XCTAssertEqual([], value)
    }

    @MainActor
    func testBackpressure() async throws {
        var current = 1

        let flow = BuildersKt.flow(block: AsyncSuspendFunction1 { (collector: FlowCollector) in
                print("Emitting")
                try! await collector.emit(value: current)
                current += 1
        })

        let stream = flow.stream(Int.self)
        var got = [Int()]
        print("Request is called before Emitting")
        for try await value in stream {
            got.append(value)
            if (value == 2) {
                break
            }
        }
        XCTAssertEqual([1, 2], got)
        XCTAssertEqual(2, current)
    }
}

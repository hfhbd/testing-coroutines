import XCTest
@testable import ios
import shared

class iosSPMTests: XCTestCase {
    @MainActor
    func testKotlinSuspendFunction1() async throws {
        let action: KotlinSuspendFunction0 = AsyncSuspendFunction0<Void> { }
        try await FlowsKt.runOnMain(action: action)
        /*
         suspend fun<T> runOnMain(action: suspend CoroutineScope.() -> T): T = withContext(Dispatchers.Main) {
         action()
         }
         */
    }

    @MainActor
    func withContext() async throws {
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
        let results = await FlowsKt.flowFrom(expectation).stream(Int.self).collect()
        XCTAssertEqual(expectation, results)
    }
    
    @MainActor
    func testFlowToAsyncStreamThrowing() async throws {
        let expectation = [1, 2, 3]
        let results = try await FlowsKt.flowFrom(expectation).streamThrowing(Int.self).collect()
        XCTAssertEqual(expectation, results)
    }

    @MainActor
    func testCancelling() async {
        let expectation = [1, 2, 3]
        let stream = FlowsKt.flowFrom(expectation).stream(Int.self)
        let t = Task { () -> [Int] in
            try await Task.sleep(nanoseconds: 3_000_000)
            return await stream.collect()
        }
        t.cancel()
        let value = (try? await t.value) ?? []
        XCTAssertEqual([], value)
    }

    class CounterS: AsyncSequence, AsyncIteratorProtocol {
        func next() async -> Int? {
            current += 1
            return current
        }

        typealias Element = Int
        func makeAsyncIterator() -> CounterS {
            self
        }

        private(set) var current = -1
    }

    func testStream() async {
        let counter = CounterS()
        var got = [Int]()
        for await value in counter {
            got.append(value)
            if (value == 2) {
                break
            }
        }
        XCTAssertEqual([0, 1, 2], got)
        XCTAssertEqual(2, counter.current)
    }

    func testBackpressureM() async throws {
        let stream = [0, 1, 2].values
        var got = [Int]()
        for try await value in stream {
            got.append(value)
            if (value == 2) {
                break
            }
        }
        XCTAssertEqual([0, 1, 2], got)
    }

    @MainActor
    func testBackpressure() async throws {
        let counter = Counter()

        let stream = counter.flow.stream(Int32.self)
        var got = [Int32]()
        for try await value in stream {
            got.append(value)
            if (value == 2) {
                break
            }
        }
        XCTAssertEqual([0, 1, 2], got)
        XCTAssertEqual(3, counter.current)
    }

    @MainActor
    func testBackpressureCounter() async throws {
        let counter = Counter()

        let stream = counter.flow.stream(Int32.self)
        var iterator = stream.makeAsyncIterator()
        let a = await iterator.next()
        XCTAssertEqual(0, a)
        let b = await iterator.next()
        XCTAssertEqual(1, b)
        let c = await iterator.next()
        XCTAssertEqual(2, c)
        XCTAssertEqual(3, counter.current)
    }
}

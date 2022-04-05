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
    func testFlowToAsyncStream() async {
        let expectation = [1, 2, 3]
        let results = await FlowsKt.flowFrom(expectation).stream(Int.self, context: Dispatchers.shared.Main).collect()
        XCTAssertEqual(expectation, results)
    }
    
    @MainActor
    func testFlowToAsyncStreamThrowing() async throws {
        let expectation = [1, 2, 3]
        let results = try await FlowsKt.flowFrom(expectation).streamThrowing(Int.self, context: Dispatchers.shared.Default).collect()
        XCTAssertEqual(expectation, results)
    }

    @MainActor
    func testCancelling() async {
        let expectation = [1, 2, 3]
        let stream = FlowsKt.flowFrom(expectation).stream(Int.self, context: Dispatchers.shared.Default)
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

    func testBackpressureM() async {
        let stream = [0, 1, 2].values
        var got = [Int]()
        for await value in stream {
            got.append(value)
            if (value == 2) {
                break
            }
        }
        XCTAssertEqual([0, 1, 2], got)
    }

    @MainActor
    func testBackpressure() async {
        let counter = Counter()

        let stream = counter.flow.stream(Int32.self, context: Dispatchers.shared.Default)
        var got = [Int32]()
        for await value in stream {
            got.append(value)
            if (value == 2) {
                break
            }
        }
        XCTAssertEqual([0, 1, 2], got)
        XCTAssertEqual(2, counter.current)
    }

    @MainActor
    func testBackpressureCounter() async {
        let counter = Counter()

        let stream = counter.flow.stream(Int32.self, context: Dispatchers.shared.Default)
        let iterator = stream.makeAsyncIterator()
        let a = await iterator.next()
        XCTAssertEqual(0, a)
        let b = await iterator.next()
        XCTAssertEqual(1, b)
        let c = await iterator.next()
        XCTAssertEqual(2, c)
        XCTAssertEqual(2, counter.current)
    }
    
    @MainActor
    func testBackpressureCounterStateFlow() async {
        let counter = Counter()
        
        let stream = counter.stateFlow.stream(Int.self, context: Dispatchers.shared.Default)
        let collector = Task {
        let iterator = stream.makeAsyncIterator()
        let a = await iterator.next()
        XCTAssertEqual(0, a)
        let b = await iterator.next()
        XCTAssertEqual(1, b)
        let c = await iterator.next()
        XCTAssertEqual(2, c)
        }
        try! await Task.sleep(nanoseconds: 1_000_000)
        counter.state.setValue(1)
        try! await Task.sleep(nanoseconds: 1_000_000)
        counter.state.setValue(2)
        await collector.value
    }
    
    func testMutableStateFlow() async {
        let flow = StateFlowKt.MutableStateFlow(value: -1)
        let collector = Task<[Int], Never> {
            var results = [Int]()
            for await value in flow.stream(Int.self, context: Dispatchers.shared.Default) {
                results.append(value)
                if (value == 2) {
                    break
                }
            }
            return results
        }
        for i in 0...3 {
            try! await Task.sleep(nanoseconds: 1_000_000)
            flow.setValue(i)
        }
        let results = await collector.value
        XCTAssertEqual([-1, 0, 1, 2], results)
    }
    
    func testMutableStateFlowCombine() async {
        let flow1 = StateFlowKt.MutableStateFlow(value: -1)
        let flow2 = StateFlowKt.MutableStateFlow(value: -1)
        let transform = AsyncSuspendFunction2<Int, Int, String> { a, b in
            "\(a) \(b)"
        }
        let combine = ZipKt.combine(flow: flow1, flow2: flow2, transform: transform)
        let collector = Task<[String], Never> {
            var results = [String]()
            for await value in combine.stream(String.self, context: Dispatchers.shared.Default) {
                results.append(value)
                if (results.count == 4) {
                    break
                }
            }
            return results
        }
        for i in 0...3 {
            try! await Task.sleep(nanoseconds: 1_000_000)
            flow1.setValue(i)
        }
        for i in 0...3 {
            try! await Task.sleep(nanoseconds: 1_000_000)
            flow2.setValue(i)
        }
        let results = await collector.value
        XCTAssertEqual(["-1 -1", "0 -1", "1 -1", "2 -1"], results)
    }
}

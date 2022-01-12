import XCTest
@testable import ios
import shared
import Combine

class iosSPMTests: XCTestCase {
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
    
    class AsyncSuspendFunction<T>: KotlinSuspendFunction1 {
        let function: (T) async -> Void
        
        init(_ function: @escaping (T) async -> Void) {
            self.function = function
        }
        
        @MainActor
        func invoke(p1: Any?) async throws -> Any? {
            await function(p1 as! T)
        }
    }
    
    @MainActor
    func testBackpressure() async throws {
        var current = 1
        let gen: (FlowCollector) async -> Void = { collector in
            try! await Builders_commonKt.withContext(context: Dispatchers.shared.Main, block: AsyncSuspendFunction<FlowCollector> { _ in
                try! await collector.emit(value: current)
            })
            current += 1
        }
        let stream = ContextKt.flowOn(BuildersKt.flow(block: AsyncSuspendFunction {
            await gen($0)
        }), context: Dispatchers.shared.Main).stream(Int.self)
        var got = [Int()]
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

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
}

import XCTest
@testable import iosApp
import shared
import Combine

class iosAppTests: XCTestCase {
    @MainActor
    func testFlowToAsyncStream() async throws {
        let expectation = [1, 2, 3]
        let results = await FlowsKt.flowFrom(expectation).stream(Int.self).collect()
        XCTAssertEqual(expectation, results)
    }
}

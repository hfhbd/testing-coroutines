import XCTest
@testable import ios
import testing_coroutines

class iosSPMTests: XCTestCase {
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
    
    func testBackpressureStateFlow() async {
        let counter = Counter()
        
        let stream = counter.state.stream(Int.self, context: Dispatchers.shared.Default)
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
        counter.increase()
        try! await Task.sleep(nanoseconds: 1_000_000)
        counter.increase()
        await collector.value
    }
    
    func testBackpressureCounterStateFlowCombined() async {
        let counter = Counter()
        let max5 = Counter.AutoMax(max: 5)
        
        let stream = counter.zip(autoMax: max5).stream(Int.self, context: Dispatchers.shared.Default)
        let iterator = stream.makeAsyncIterator()
        
        let a = await iterator.next()
        XCTAssertEqual(0, a)
        let b = await iterator.next()
        XCTAssertEqual(1, b)
        let c = await iterator.next()
        XCTAssertEqual(2, c)
        let d = await iterator.next()
        XCTAssertEqual(3, d)
        let e = await iterator.next()
        XCTAssertEqual(4, e)
        
        XCTAssertEqual(4, counter.current)
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
}

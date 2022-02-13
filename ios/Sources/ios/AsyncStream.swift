import Combine
import shared
import SwiftUI

struct FlowStream<T>: AsyncSequence {
    func makeAsyncIterator() -> FlowAsyncIterator {
        FlowAsyncIterator(flow: flow)
    }

    typealias AsyncIterator = FlowAsyncIterator

    typealias Element = T

    let flow: Flow
    init (_ type: T.Type, flow: Flow) {
        self.flow = flow
    }

    struct FlowAsyncIterator: AsyncIteratorProtocol {
        private let iterator: IteratorAsync

        init(flow: Flow) {
            self.iterator = FlowsKt.asAsyncIterable(flow)
        }

        @MainActor
        func next() async throws -> T? {
            if(Task.isCancelled) {
                iterator.cancel()
                return nil
            }
            return try await iterator.next() as? T? ?? nil
        }

        typealias Element = T
    }
}

extension Flow {
    func stream<T>(_ t: T.Type) -> FlowStream<T> {
        FlowStream(t, flow: self)
    }
}

extension AsyncSequence {
    func collect() async rethrows -> [Element] {
        return try await reduce(into: [Element]()) {
            $0.append($1)
        }
    }
}

class AsyncSuspendFunction0<R>: KotlinSuspendFunction0 {
    let function: () async throws -> R

    init(_ function: @escaping () async throws -> R) {
        self.function = function
    }

    @MainActor
    func invoke() async throws -> Any? {
        try await function()
    }
}

class AsyncSuspendFunction1<T, R>: KotlinSuspendFunction1 {
    let function: (T) async throws -> R

    init(_ function: @escaping (T) async throws -> R) {
        self.function = function
    }

    @MainActor
    func invoke(p1: Any?) async throws -> Any? {
        try await function(p1 as! T)
    }
}

class AsyncSuspendFunction2<T1, T2, R>: KotlinSuspendFunction2 {
    let function: (T1, T2) async throws -> R

    init(_ function: @escaping (T1, T2) async -> R) {
        self.function = function
    }

    @MainActor
    func invoke(p1: Any?, p2: Any?) async throws -> Any? {
        try await function(p1 as! T1, p2 as! T2)
    }
}

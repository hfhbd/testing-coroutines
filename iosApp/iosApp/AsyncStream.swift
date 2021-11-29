import Combine
import shared
import SwiftUI

extension Flow {
    @MainActor
    func throwingStream<T>(_ type: T.Type) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream<T, Error>() { cont in
            let job = FlowsKt.collecting(self) {
                cont.yield($0 as! T)
            } onCompletion: {
                if let error = $0 {
                    cont.finish(throwing: error.asError())
                } else {
                    cont.finish(throwing: nil)
                }
            }
            cont.onTermination = { @Sendable termination in
                if case .cancelled = termination {
                    job.cancel()
                }
            }
        }
    }

    @MainActor
    func stream<T>(_ type: T.Type) -> AsyncStream<T> {
        AsyncStream { cont in
            let job = FlowsKt.collecting(self) {
                cont.yield($0 as! T)
            } onCompletion: {
                if let error = $0 {
                    fatalError(error.asError().localizedDescription)
                } else {
                    cont.finish()
                }
            }
            cont.onTermination = { @Sendable termination in
                if case .cancelled = termination {
                    job.cancel()
                }
            }
        }
    }
}

extension View {
    @MainActor
    func collect<T>(_ flow: MutableStateFlow, currentValue: T, perform action: @escaping (T) -> Void) -> some View where T: Equatable {
        onChange(of: currentValue) { newValue in
            flow.setValue(newValue)
        }
        .onAppear(perform: {
            Task {
                for await newValue in flow.stream(T.self) {
                    action(newValue)
                }
            }
        })
    }
}

extension Sequence {
    func stream() -> AsyncStream<Element> {
        AsyncStream { cont in
            for element in self {
                cont.yield(element)
            }
            cont.finish()
        }
    }
}

extension AsyncSequence {
    func collect() async rethrows -> [Element] {
        return try await reduce(into: [Element]()) { $0.append($1) }
    }
}

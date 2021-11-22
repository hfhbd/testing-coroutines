import Combine
import shared
import SwiftUI

extension Flow {
    @MainActor
    func throwingStream<T>(_ type: T.Type) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream<T, Error>() { cont in
            Task {
                do {
                    try await FlowsKt.collecting(self) {
                        cont.yield($0 as! T)
                    }
                    cont.finish(throwing: nil)
                } catch {
                    cont.finish(throwing: error)
                }
            }
        }
    }
    
    @MainActor
    func stream<T>(_ type: T.Type) -> AsyncStream<T> {
        AsyncStream { cont in
            Task {
                do {
                    try await FlowsKt.collecting(self) {
                        cont.yield($0 as! T)
                    }
                    cont.finish()
                } catch {
                    fatalError(error.localizedDescription)
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

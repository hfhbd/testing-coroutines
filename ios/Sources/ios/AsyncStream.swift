import shared

struct FlowStream<T>: AsyncSequence {
    func makeAsyncIterator() -> FlowAsyncIterator {
        FlowAsyncIterator(FlowsKt.asAsyncIterable(flow, context: context))
    }

    typealias AsyncIterator = FlowAsyncIterator

    typealias Element = T

    private let flow: Flow
    private let context: KotlinCoroutineContext

    init (_ type: T.Type, flow: Flow, context: KotlinCoroutineContext) {
        self.flow = flow
        self.context = context
    }

    struct FlowAsyncIterator: AsyncIteratorProtocol {
        private let iterator: IteratorAsync

        init(_ iterator: IteratorAsync) {
            self.iterator = iterator
        }

        @MainActor
        func next() async -> T? {
            try! await withTaskCancellationHandler(handler: {
                iterator.cancel()
            }) {
                do {
                    return try await iterator.next() as! T?
                } catch let error as NSError {
                    let kotlinException = error.kotlinException
                    if kotlinException is KotlinCancellationException {
                        return nil
                    } else {
                        throw error
                    }
                }
            }
        }

        typealias Element = T
    }
}

extension Flow {
    func stream<T>(_ t: T.Type, context: KotlinCoroutineContext = Dispatchers.shared.Default) -> FlowStream<T> {
        FlowStream(t, flow: self, context: context)
    }
}

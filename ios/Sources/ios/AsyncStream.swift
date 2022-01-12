import Combine
import shared
import SwiftUI

struct FlowPublisher<T>: Publisher {
    let flow: Flow

    func receive<S>(subscriber: S) where S: Subscriber, Error == S.Failure, T == S.Input {
        let subscription = FlowSubscription(flow: flow, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }

    typealias Output = T
    typealias Failure = Error


    private class FlowSubscription<S: Subscriber>: Subscription where S.Input == T, S.Failure == Error {
        let flow: Flow
        private var cancelling: Cancelable! = nil
        private let subscriber: S

        init(flow: Flow, subscriber: S) {
            self.flow = flow
            self.subscriber = subscriber
        }

        func request(_ demand: Subscribers.Demand) {
            var demand = demand

            while demand > 0 {
                self.cancelling = FlowsKt.collectingBlocking(flow, action: { value in
                    demand -= 1
                    demand += self.subscriber.receive(value as! T)
                }, onCompletion: { cause in
                    if let cause = cause {
                        self.subscriber.receive(completion: .failure(cause.asError()))
                    } else {
                        self.subscriber.receive(completion: .finished)
                    }
                    demand = Subscribers.Demand.none
                })
            }
        }

        func cancel() {
            self.cancelling.cancel()
        }

        let combineIdentifier = CombineIdentifier()
    }
}

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
            return try await iterator.next() as! T?
        }

        typealias Element = T
    }
}

extension Flow {
    func publisher<T>(_ t: T.Type) -> FlowPublisher<T> {
        FlowPublisher(flow: self)
    }

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

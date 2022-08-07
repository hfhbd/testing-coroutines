//
//  ViewModel.swift
//  composetodo (iOS)
//
//  Created by Philip Wedemann on 15.04.22.
//

import SwiftUI
import Combine
import testing_coroutines

extension Counter: ObservableObject {
    @MainActor
    func binding<T>(_ keyPath: KeyPath<Counter, MutableStateFlow>, t: T.Type) -> Binding<T> where T: Equatable {
        binding(flow: self[keyPath: keyPath], t: t)
    }
    
    @MainActor
    func binding<T>(flow: MutableStateFlow, t: T.Type) -> Binding<T> where T: Equatable {
        Task {
            let oldValue = flow.value as! T
            for await newValue in flow.stream(t) {
                if (oldValue != newValue) {
                    self.objectWillChange.send()
                    break
                }
            }
        }
        return .init(get: {
            flow.value as! T
        }, set: {
            flow.setValue($0)
        })
    }
}

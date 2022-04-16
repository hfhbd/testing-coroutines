//
//  ViewModel.swift
//  composetodo (iOS)
//
//  Created by Philip Wedemann on 15.04.22.
//

import SwiftUI
import Combine
import shared

extension Counter: ObservableObject {
    func binding<T>(_ keyPath: KeyPath<Counter, MutableStateFlow>, t: T.Type) -> Binding<T> where T: Equatable {
        binding(flow: self[keyPath: keyPath], t: t)
    }
    
    func binding<T>(flow: MutableStateFlow, t: T.Type) -> Binding<T> where T: Equatable {
        .init(get: {
            flow.value as! T
        }, set: { new in
            if (new != flow.value as! T) {
                self.objectWillChange.send()
                flow.setValue(new)
            }
        })
    }
}

//
//  ContentView.swift
//  iosApp
//
//  Created by Philip Wedemann on 15.03.22.
//

import SwiftUI
import shared

struct ContentView: View {
    let viewModel: Counter

    @State var counter = 0
    var body: some View {
        Button("\(counter)") {
            viewModel.state.setValue(counter + 1)
        }
            .padding()
            .task {
                for await i in viewModel.stateFlow.stream(Int.self, context: Dispatchers.shared.Default) {
                    self.counter = i
                }
            }
    }
}

struct Previews_ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: Counter())
    }
}

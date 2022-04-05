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
        TabView {
        Button("\(counter)") {
            viewModel.state.setValue(counter + 1)
        }
            .padding()
            .task {
                for await i in viewModel.stateFlow.stream(Int.self) {
                    self.counter = i
                }
            }.tabItem {
                Text("Counter")
            }

            Text("A").tabItem {
                Text("A")
            }
        }

    }
}

struct Previews_ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: Counter())
    }
}

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
    @State var counter2 = 0
    @State var counter3 = 0
    
    var body: some View {
        Form {
            Button("\(counter)") {
                viewModel.increase()
            }.task {
                for await i in viewModel.state.stream(Int.self) {
                    counter = i
                }
            }
            
            Text("\(counter2)")
                .task {
                    for await i in viewModel.state.stream(Int.self) {
                        counter2 = i
                    }
                }
            
            Text("\(counter3)")
        }
            .task {
                for await i in viewModel.state.stream(Int.self) {
                    counter3 = i
                }
            }
    }
}

struct Previews_ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: Counter())
    }
}

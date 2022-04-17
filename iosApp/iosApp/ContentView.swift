//
//  ContentView.swift
//  iosApp
//
//  Created by Philip Wedemann on 15.03.22.
//

import SwiftUI
import testing_coroutines

struct ContentView: View {
    @StateObject var viewModel = Counter()
    
    @State var counter = 0
    @State var counter2 = 0
    @State var twice = ""
    @State var validLogin = false
    @State var passwordValid = false
    
    var body: some View {
        Form {
            TextField("Username", text: viewModel.binding(\.username, t: String.self))
            TextField("Password", text: viewModel.binding(\.password, t: String.self))
            Group {
                if passwordValid {
                    Text("valid Password")
                } else {
                    Text("No valid password")
                }
            }.task {
                for await new in viewModel.isLonger.stream(Bool.self) {
                    passwordValid = new
                }
            }
            
            Group {
                if validLogin {
                    Text("valid Login")
                } else {
                    Text("No valid login")
                }
            }.task {
                for await new in viewModel.isValid.stream(Bool.self) {
                    validLogin = new
                }
            }
            
            Button("\(counter)") {
                viewModel.increase()
            }.task {
                for await new in viewModel.state.stream(Int.self) {
                    counter = new
                }
            }
            
            Text("\(counter2)").task {
                for await new in viewModel.state.stream(Int.self) {
                    counter2 = new
                }
            }
            Text(twice).task {
                for await new in viewModel.state2.stream(String.self) {
                    twice = new
                }
            }
        }
    }
}

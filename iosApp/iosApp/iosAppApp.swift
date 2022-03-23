//
//  iosAppApp.swift
//  iosApp
//
//  Created by Philip Wedemann on 15.03.22.
//

import SwiftUI
import shared

@main
struct iosAppApp: App {
    let viewModel = Counter()
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
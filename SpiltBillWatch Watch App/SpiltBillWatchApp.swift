//
//  SpiltBillWatchApp.swift
//  SpiltBillWatch Watch App
//
//  Created by Jason Ze on 2024/5/24.
//

import SwiftUI

@main
struct SpiltBillWatch_Watch_AppApp: App {
    @StateObject private var dataStore = WatchDataStore()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(dataStore)

            }
        }
    }
}

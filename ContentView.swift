//
//  ContentView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/12.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore

    // used to track whether the user is authenticated or not
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    
    
    var body: some View {
            NavigationView {
                if isAuthenticated {
                    TabView {
                        FriendTable()
                        .tabItem {
                                       Label("Friends", systemImage: "person.2.fill")
                                   }
                        ExpenseTable()
                        .tabItem {
                               Label("Expenses", systemImage: "list.bullet")
                           }
                       ProfileView(isAuthenticated: $isAuthenticated)
                           .tabItem {
                               Label("Profile", systemImage: "person.circle.fill")
                           }
}
                } else {
                    AuthenticationView(isAuthenticated: $isAuthenticated)
                }
            }
            .onAppear {
                       // Automatically set isAuthenticated to true if there's a userId in UserDefaults
                       if let _ = UserDefaults.standard.string(forKey: "userId") {
                           isAuthenticated = true
                       }
                   }
        }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
}

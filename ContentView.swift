//
//  ContentView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/12.
//

import SwiftUI

/// ContentView is the main view of the application. It displays different views based on the authentication state of the user.
struct ContentView: View {
    @EnvironmentObject var dataStore: DataStore

    /// A property used to track whether the user is authenticated or not. The value is stored in AppStorage for persistence.
    @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
    
    var body: some View {
        NavigationView {
            if isAuthenticated {
                // Display the main content of the app using a TabView with Friends, Expenses, and Profile tabs
                TabView {
                    // FriendTable view shows a list of friends
                    FriendTable()
                        .tabItem {
                            Label("Friends", systemImage: "person.2.fill")
                        }
                    // ExpenseTable view shows a list of expenses
                    ExpenseTable()
                        .tabItem {
                            Label("Expenses", systemImage: "list.bullet")
                        }
                    // ProfileView allows the user to view and edit their profile, and log out
                    ProfileView(isAuthenticated: $isAuthenticated)
                        .tabItem {
                            Label("Profile", systemImage: "person.circle.fill")
                        }
                }
            } else {
                // Display the authentication view if the user is not authenticated
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


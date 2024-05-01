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
                                Text("Friend")
                            }
                        
                        GroupTable()
                            .tabItem {
                                Text("Group")
                            }
                        
                        
                        ExpenseTable()
                            .tabItem {
                                Text("Expense")
                            }
                        
                      
                        
                        Profile()
                            .tabItem {
                                Text("Profile")
                            }
                    }
                } else {
                    AuthenticationView(isAuthenticated: $isAuthenticated)
                }
            }
        }
}

#Preview {
    ContentView()
        .environmentObject(DataStore())
}

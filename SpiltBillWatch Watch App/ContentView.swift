//
//  ContentView.swift
//  SpiltBillWatch Watch App
//
//  Created by Jason Ze on 2024/5/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataStore: WatchDataStore

       var body: some View {
           VStack {
               NavigationLink(destination: FriendListView().environmentObject(dataStore)) {
                   Text("Friends")
               }
               .padding()
               
               NavigationLink(destination: ExpenseListView().environmentObject(dataStore)) {
                   Text("Expenses")
               }
               .padding()
           }
           .navigationTitle("Main Menu")
       }
}



//
//  FriendListView.swift
//  SpiltBillWatch Watch App
//
//  Created by Jason Ze on 2024/5/24.
//
import SwiftUI

struct FriendListView: View {
    @EnvironmentObject var dataStore: WatchDataStore

    var body: some View {
        List {
            ForEach(dataStore.friends, id: \.id) { friend in
                NavigationLink(destination: FriendDetailView(friend: friend).environmentObject(dataStore)) {
                    Text(friend.Name)
                }
            }
        }
        .navigationTitle("Friends")
    }
}

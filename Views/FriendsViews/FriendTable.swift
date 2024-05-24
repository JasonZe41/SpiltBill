//
//  FriendTable.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//

import SwiftUI

/// A SwiftUI view that displays a list of friends and provides options to add or delete friends.
struct FriendTable: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingAddFriendView = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            List {
                // Loop through the friends in the dataStore and create a row for each friend.
                ForEach(dataStore.friends) { friend in
                    FriendRow(friend: friend)
                        .environmentObject(dataStore)
                }
                // Enable deletion of friends.
                .onDelete(perform: deleteFriend)
            }
            .refreshable {
                dataStore.fetchFriends()
            }
            .navigationTitle("Friends")
            .toolbar {
                // Add a refresh button to the navigation bar.
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dataStore.fetchFriends() // Refresh the list of friends
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                // Add a button to present the AddFriend view.
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFriendView = true }) {
                        Label("Add Friend", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriendView) {
                AddFriends().environmentObject(dataStore)
            }
        }
    }

    /// Deletes a friend from the dataStore.
    /// - Parameter offsets: The index set of the friend to be deleted.
    private func deleteFriend(at offsets: IndexSet) {
        offsets.forEach { index in
            let friendID = dataStore.friends[index].friendshipID
            dataStore.deleteFriend(friendshipID: friendID) { result in
                switch result {
                case .success(let success):
                    print("Friendship successfully deleted: \(success)")
                    DispatchQueue.main.async {
                        dataStore.friends.remove(atOffsets: offsets) // Update the local model after successful deletion
                    }
                case .failure(let error):
                    print("Failed to delete friendship: \(error.localizedDescription)")
                }
            }
        }
    }
}

/// A SwiftUI view that represents a single row in the FriendTable.
struct FriendRow: View {
    var friend: Participant
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationLink(destination: FriendDetailView(friend: friend).environmentObject(dataStore)) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading) {
                    Text(friend.Name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(friend.PhoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

//
//  FriendTable.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//

import SwiftUI

struct FriendTable: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingAddFriendView = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            List {
                ForEach(dataStore.friends) { friend in
                    FriendRow(friend: friend)
                        .environmentObject(dataStore)
                }
                .onDelete(perform: deleteFriend)
            }
            .refreshable {
                dataStore.fetchFriends()
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dataStore.fetchFriends() // Refresh the list of friends
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
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

struct FriendRow: View {
    var friend: Participant
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationLink(destination: FriendDetailView(friend: friend).environmentObject(dataStore)) {
            HStack {
                Image(systemName: "person.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.blue))
                    .foregroundColor(.white)
                VStack(alignment: .leading) {
                    Text(friend.Name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(friend.PhoneNumber)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
        }
    }
}

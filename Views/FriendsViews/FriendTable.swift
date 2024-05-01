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
              }
              .onDelete(perform: deleteFriend)
          }
          .onReceive(dataStore.$friends) { _ in
                 print("Friends updated.")
             }
          .navigationTitle("Friends")
          .toolbar {
              // Button to refresh or add friends
              ToolbarItem(placement: .navigationBarTrailing) {
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

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading) {
                Text(friend.Name)
                    .fontWeight(.bold)
                Text(friend.PhoneNumber)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}


#Preview {
    FriendTable()
}

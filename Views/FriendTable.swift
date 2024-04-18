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
      Text(dataStore.test() ?? "None")
      NavigationView {
          List {
              ForEach(dataStore.friends) { friend in
                  FriendRow(friend: friend)
              }
              .onDelete(perform: deleteFriend)
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
          }
      }
      
//      NavigationStack {
//          List {
//              ForEach(dataStore.friends) { friend in
//                  NavigationLink(destination: FriendDetailView(friend: friend).environmentObject(dataStore)) {
//                      HStack {
//                          Image(systemName: "person.fill")
//                              .resizable()
//                              .scaledToFit()
//                              .frame(width: 24, height: 24)
//                              .foregroundColor(.accentColor)
//                              .padding(.trailing, 8)
//                          
//                          VStack(alignment: .leading) {
//                              Text(friend.name)
//                                  .font(.headline)
//                              
//                              Text(friend.phoneNumber)
//                                  .font(.subheadline)
//                                  .foregroundColor(.secondary)
//                          }
//                      }
//                      .padding(.vertical, 4)
//                  }
//              }
//              .onDelete(perform: deleteFriend)
//          }
//          .listStyle(PlainListStyle())
//          .toolbar {
//              ToolbarItem(placement: .navigationBarTrailing) {
//                  Button(action: { showingAddFriendView = true }) {
//                      Label("Add Friend", systemImage: "plus")
//                  }
//              }
//          }
//          .navigationTitle("Friends")
//          .navigationBarTitleDisplayMode(.inline)
//
//          .refreshable {
//              // Refresh friends list
//              dataStore.fetchFriends()
//          }
//      }
      
  }
  private func deleteFriend(at offsets: IndexSet) {
          offsets.forEach { index in
              let friend = dataStore.friends[index]
              dataStore.deleteFriend(friendID: friend.id)
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

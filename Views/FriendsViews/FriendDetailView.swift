//
//  FriendDetailView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//

import SwiftUI


struct FriendDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    var friend: Participant
    
    
    var body: some View {
        VStack {
           Text("hello")
        }
        .navigationTitle(friend.Name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
   
}

#Preview {
    FriendDetailView(friend: DataStore().friends[0])
}

//
//  AddFriends.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/22.
//

import SwiftUI

struct AddFriends: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var phoneNumberOrEmail: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    var body: some View {
        NavigationView {
            Form {
                TextField("Phone number or Email", text: $phoneNumberOrEmail)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                
                Button("Search") {
                    searchForUser()
                }
                .disabled(phoneNumberOrEmail.isEmpty)
            }
            .navigationBarTitle("Add Friend", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Friend Add"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    
    
    private func searchForUser() {
        dataStore.searchUser(phoneNumberOrEmail: phoneNumberOrEmail) { result in
            switch result {
            case .success(let userFound):
                if userFound {
                    alertMessage = "Friend added successfully."
                } else {
                    alertMessage = "User not found."
                }
                showingAlert = true
                
            case .failure(let error):
                alertMessage = "An error occurred: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}


#Preview {
    AddFriends()
}

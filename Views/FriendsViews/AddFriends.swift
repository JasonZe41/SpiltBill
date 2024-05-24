//
//  AddFriends.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/22.
//
import SwiftUI

/// A SwiftUI view for adding new friends by searching for them using their phone number or email.
struct AddFriends: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss
    
    @State private var phoneNumberOrEmail: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Find a Friend").font(.headline)) {
                    TextField("Phone number or Email", text: $phoneNumberOrEmail)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .padding(.vertical, 10)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }

                Button(action: searchForUser) {
                    Text("Search")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(phoneNumberOrEmail.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(phoneNumberOrEmail.isEmpty)
            }
            .padding()
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
    
    /// Searches for a user by their phone number or email.
    /// If found, adds them as a friend. Otherwise, shows an alert message.
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



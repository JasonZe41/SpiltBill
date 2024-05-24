//
//  Profile.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/22.
//
import SwiftUI

/// A view representing the user's profile page, displaying user information and allowing the user to log out.
struct ProfileView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var isAuthenticated: Bool

    var body: some View {
        NavigationView {
            VStack {
                if let currentUser = dataStore.currentUser {
                    UserInformationView(participant: currentUser)
                    Spacer()
                    Button(action: {
                        logout()
                    }) {
                        Text("Log Out")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding()
                } else {
                    VStack {
                        ProgressView()
                        Text("Loading user information...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .onAppear {
                        dataStore.fetchCurrentUser { user in
                            DispatchQueue.main.async {
                                self.dataStore.currentUser = user
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    /// Logs out the current user and updates the authentication state.
    private func logout() {
        dataStore.logout()
        isAuthenticated = false
    }
}

/// A subview that displays the user's information in a form-like layout.
struct UserInformationView: View {
    var participant: Participant

    var body: some View {
        Form {
            Section(header: Text("User Information").font(.headline).foregroundColor(.blue)) {
                HStack {
                    Spacer()
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding()
                        .shadow(radius: 10)
                    Spacer()
                }

                HStack {
                    Text("Name")
                        .bold()
                    Spacer()
                    Text(participant.Name)
                }

                HStack {
                    Text("Phone Number")
                        .bold()
                    Spacer()
                    Text(participant.PhoneNumber)
                }

                HStack {
                    Text("Email")
                        .bold()
                    Spacer()
                    Text(participant.Email)
                }
            }
        }
        .padding(.top, 20)
    }
}

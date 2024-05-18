//
//  AuthenticationView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/12.
//
import SwiftUI
import Firebase

struct AuthenticationView: View {
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @Binding var isAuthenticated: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isSignUp {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
                
                Button(action: {
                    if isSignUp {
                        signUp()
                    } else {
                        logIn()
                    }
                }) {
                    Text(isSignUp ? "Sign Up" : "Log In")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text("Switch to \(isSignUp ? "Log In" : "Sign Up")")
                        .foregroundColor(.blue)
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle(isSignUp ? "Sign Up" : "Log In")
        }
    }

    private func logIn() {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            // Successful login, change isAuthenticated
            if let user = authResult?.user {
                self.storeUserId(userId: user.uid)
                self.isAuthenticated = true
            }
        }
    }

    private func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            // Successful sign up, now save additional info to Firestore
            if let user = authResult?.user {
                self.storeUserId(userId: user.uid)
                let db = Firestore.firestore()
                db.collection("User").document(user.uid).setData([
                    "Name": self.name,
                    "Email": self.email,
                    "PhoneNumber": self.phoneNumber
                ]) { error in
                    if let error = error {
                        self.errorMessage = "Error saving user info: \(error.localizedDescription)"
                        return
                    }
                    self.isAuthenticated = true
                }
            }
        }
    }
    
    private func storeUserId(userId: String) {
        UserDefaults.standard.set(userId, forKey: "userId")
    }
}

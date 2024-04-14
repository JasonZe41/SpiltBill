//
//  Datastore.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//

import Foundation
import FirebaseFirestore
import Firebase

class DataStore: ObservableObject {
    private var db = Firestore.firestore()
    @Published var expenses: [Expense] = []
    
    @Published var friends: [Participant] = []
    
    
    @Published var groups: [Group] = []
    
    
    /// Initializes the `DataStore` instance and fetch the groups, expenses, and freinds from firestore
    init() {
        //            fetchGroups()
        //            fetchExpenses()
        fetchFriends() // this is fetching friends
    }
    
    
    private func getCurrentUserID() -> String? {
        UserDefaults.standard.string(forKey: "currentUserID")
    }
    
    
    func fetchExpenses(){
        guard let userID = getCurrentUserID() else { return }
        db.collection("ExpenseParticipation")
            .whereField("UserID", isEqualTo: userID)
            .addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let documents = querySnapshot?.documents else {
                    print("No documents in 'ExpenseParticipation'")
                    return
                }
                let expenseIDs = documents.map { $0["ExpenseID"] as? String }.compactMap { $0 }
                self?.expenses.removeAll() // Clear current list
                for expenseID in expenseIDs {
                    self?.db.collection("Expense").document(expenseID).getDocument { (document, error) in
                        if let document = document, let expense = try? document.data(as: Expense.self) {
                            DispatchQueue.main.async {
                                self?.expenses.append(expense)
                            }
                        }
                    }
                }
            }
    }
    
    
    
    
    func fetchFriends() {
        guard let userID = getCurrentUserID() else { return }
        
        let friendsRef = db.collection("Friends")
        var friendRelations: [String: String] = [:] // Maps friend's userID to friendship document ID
        
        // Define a group to handle asynchronous fetches
        let fetchGroup = DispatchGroup()
        
        // First Query: Current user is UserID1
        fetchGroup.enter()
        friendsRef.whereField("UserID1", isEqualTo: userID).getDocuments { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents found for UserID1")
                fetchGroup.leave()
                return
            }
            for document in documents {
                if let friendID = document["UserID2"] as? String {
                    friendRelations[friendID] = document.documentID // Store friendship ID
                }
            }
            fetchGroup.leave()
        }
        
        // Second Query: Current user is UserID2
        fetchGroup.enter()
        friendsRef.whereField("UserID2", isEqualTo: userID).getDocuments { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("No documents found for UserID2")
                fetchGroup.leave()
                return
            }
            for document in documents {
                if let friendID = document["UserID1"] as? String {
                    friendRelations[friendID] = document.documentID // Store friendship ID
                }
            }
            fetchGroup.leave()
        }
        
        // After both queries complete
        
        // After both queries complete
        fetchGroup.notify(queue: .main) { [weak self] in
            // Clear existing friends to avoid duplicates
            self?.friends.removeAll()
            
            // Fetch details for each unique friendID
            for (friendID, friendshipID) in friendRelations {
                fetchGroup.enter()
                self?.db.collection("Users").document(friendID).getDocument { (document, error) in
                    if let document = document, document.exists, var friend = try? document.data(as: Participant.self) {
                        friend.id = friendID
                        friend.friendshipID = friendshipID // Correctly associate the friendship ID
                        
                        DispatchQueue.main.async {
                            // Prevent duplicates
                            if !(self?.friends.contains(where: { $0.id == friend.id }) ?? false) {
                                self?.friends.append(friend)
                            }
                            fetchGroup.leave()
                        }
                    } else {
                        fetchGroup.leave()
                    }
                }
            }
        }
        
    }
}

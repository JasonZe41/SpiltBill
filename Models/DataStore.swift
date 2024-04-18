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
    
    func test() -> String? {
        UserDefaults.standard.string(forKey: "currentUserID")
    }
    
    
    
    
    // MARK: - Expenses Operation  (fetch, add, delete, or update)

    
    func fetchExpenses() {
        guard let currentUserID = getCurrentUserID() else {
            print("No current user ID available")
            return
        }
        
        db.collection("Expenses").getDocuments { [weak self] snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching expenses: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let group = DispatchGroup()
            
            for document in documents {
                group.enter()
                let expenseID = document.documentID
                document.reference.collection("ExpenseParticipations").getDocuments { subSnapshot, subError in
                    defer { group.leave() }
                    
                    guard let participationDocuments = subSnapshot?.documents, subError == nil else {
                        print("Error fetching participations: \(subError?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    let participants = participationDocuments.compactMap { subDoc -> Participant? in
                        let userID = subDoc.data()["UserID"] as? String ?? ""
                        if userID == currentUserID {
                            return Participant(
                                Name: "Fetched User Name", // Placeholder
                                id: userID,
                                PhoneNumber: "Fetched Phone", // Placeholder
                                Email: "Fetched Email", // Placeholder
                                friendshipID: "Fetched Friendship ID" // Placeholder
                            )
                        }
                        return nil
                    }
                    
                    if !participants.isEmpty {
                        let expense = Expense(
                            id: expenseID,
                            groupID: document.data()["GroupID"] as? String ?? "",
                            description: document.data()["Description"] as? String ?? "",
                            date: (document.data()["Date"] as? Timestamp)?.dateValue() ?? Date(),
                            totalAmount: document.data()["TotalAmount"] as? Double ?? 0.0,
                            splitType: SplitType(rawValue: document.data()["SplitType"] as? String ?? "") ?? .equally,
                            participants: participants
                        )
                        
                        DispatchQueue.main.async {
                            self?.expenses.append(expense)
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                print("Completed fetching all relevant expenses for current user")
            }
        }
    }
        
        
            
            
            func addExpense(expense: Expense, completion: @escaping (Bool, Error?) -> Void) {
                guard let userID = getCurrentUserID() else {
                    completion(false, NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User ID not found"]))
                    return
                }
                
                var ref: DocumentReference? = nil
                ref = db.collection("Expenses").addDocument(data: [
                    "description": expense.description,
                    "totalAmount": expense.totalAmount,
                    "date": Timestamp(date: expense.date),
                    "groupID": expense.groupID,
                    "splitType": expense.splitType.rawValue,
                    "participants": expense.participants.map { ["id": $0.id, "name": $0.Name] }
                ]) { error in
                    if let error = error {
                        completion(false, error)
                    } else {
                        self.expenses.append(expense)
                        print("Document added with ID: \(ref!.documentID)")
                        completion(true, nil)
                    }
                }
            }
            
    
    func deleteExpense(expenseID: String, completion: @escaping (Bool, Error?) -> Void) {
            let expenseRef = db.collection("Expenses").document(expenseID)

            // First, delete all sub-collection documents
            deleteParticipations(for: expenseRef) { [weak self] success, error in
                guard success else {
                    completion(false, error)
                    return
                }
                
                // Now delete the main expense document
                expenseRef.delete { error in
                    if let error = error {
                        completion(false, error)
                    } else {
                        DispatchQueue.main.async {
                            // Remove the expense from the local list
                            self?.expenses.removeAll { $0.id == expenseID }
                            completion(true, nil)
                        }
                    }
                }
            }
        }

        /// Helper function to delete all participations for an expense
        private func deleteParticipations(for expenseRef: DocumentReference, completion: @escaping (Bool, Error?) -> Void) {
            // Retrieve all participation documents
            expenseRef.collection("ExpenseParticipations").getDocuments { (snapshot, error) in
                guard let documents = snapshot?.documents else {
                    completion(false, error)
                    return
                }

                let batch = self.db.batch()
                documents.forEach { doc in
                    batch.deleteDocument(doc.reference)
                }

                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        completion(false, error)
                    } else {
                        completion(true, nil)
                    }
                }
            }
        }
            
            
            
            // MARK: - Freinds Operation (fetch, add, delete)
            
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
            
            func deleteFriend(friendID: String) {
                db.collection("Friends").document(friendID).delete { error in
                    if let error = error {
                        print("Error removing friend: \(error.localizedDescription)")
                    } else {
                        // Also remove the friend from the local 'friends' array
                        DispatchQueue.main.async {
                            self.friends.removeAll { $0.id == friendID }
                        }
                    }
                }
            }
            
            
            
            // MARK: - Group Operation (fetch, add, delete, update)
            
            
        }
    

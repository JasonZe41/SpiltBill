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
    @Published var currentUser: Participant?

//    @Published var paymentDetails : [PaymentDetail] = []
    
    
    /// Initializes the `DataStore` instance and fetch the groups, expenses, and freinds from firestore
    init() {
        //            fetchGroups()
        
        fetchCurrentUser { user in
                   DispatchQueue.main.async {
                       self.currentUser = user
                   }
               }
        
        fetchExpenses { fetchedExpenses in
                    DispatchQueue.main.async {
                        self.expenses = fetchedExpenses
                    }
                }
        fetchFriends()
    }
    
    
    private func getCurrentUserID() -> String? {
        UserDefaults.standard.string(forKey: "userId")
    }
    
    func logout() {
            // Clear user defaults or any other storage used for user session
            UserDefaults.standard.removeObject(forKey: "userId")
            currentUser = nil
        }
        
    
    func fetchCurrentUser(completion: @escaping (Participant?) -> Void) {
            guard let userID = getCurrentUserID() else {
                print("User ID not available")
                completion(nil)  // No user ID available, return nil
                return
            }

            let userRef = db.collection("User").document(userID)
            userRef.getDocument { document, error in
                if let document = document, document.exists {
                    let data = document.data()
                    let participant = Participant(
                        Name: data?["Name"] as? String ?? "Unknown",
                        PhoneNumber: data?["PhoneNumber"] as? String ?? "No Phone Number",
                        Email: data?["Email"] as? String ?? "No Email",
                        friendshipID: "",
                        id: document.documentID
                    )
                    completion(participant)  // Return the fetched participant
                } else {
                    print("Document does not exist: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)  // Document does not exist, return nil
                }
            }
        }
    
    
    
    // MARK: - Expenses Operation  (fetch, add, delete, or update)
 

    func fetchExpenses(completion: @escaping ([Expense]) -> Void) {
        guard let currentUserID = getCurrentUserID() else {
            print("User ID not available")
            completion([])
            return
        }

        let userRef = db.collection("User").document(currentUserID)
        let participationsRef = db.collection("ExpenseParticipations")

        
        // Looking through ExpenseParticipations collection to find all expense invoeld with current user
        participationsRef.whereField("UserID", isEqualTo: userRef).getDocuments { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents, !documents.isEmpty, error == nil else {
                print("No expense participations found or error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            let expenseIDs = documents.compactMap { ($0.data()["ExpenseID"] as? DocumentReference)?.documentID }
            self?.fetchExpensesDetails(fromIDs: expenseIDs, completion: completion)
        }
    }

    
    // function that based on expenseID to fetch all expense and construct the expense struct and append into expense lists.
    private func fetchExpensesDetails(fromIDs expenseIDs: [String], completion: @escaping ([Expense]) -> Void) {
        let expensesRef = db.collection("Expense")
        var expenses = [Expense]()
        let group = DispatchGroup()

        for expenseID in expenseIDs {
            group.enter()
            expensesRef.document(expenseID).getDocument { (document, error) in
                guard let document = document, document.exists, let data = document.data(), error == nil else {
                    print("Error fetching expense details: \(error?.localizedDescription ?? "No data")")
                    group.leave()
                    return
                }

                self.constructExpense(from: data, documentID: document.documentID) { expense in
                    expenses.append(expense)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(expenses)
        }
    }

    
    private func constructExpense(from data: [String: Any], documentID: String, completion: @escaping (Expense) -> Void) {
//        let groupID = (data["GroupID"] as? DocumentReference)?.documentID ?? "Unknown Group"
        let description = data["Description"] as? String ?? "No Description"
        let totalAmount = data["TotalAmount"] as? Double ?? 0.0
        let splitTypeRaw = data["SplitType"] as? String ?? "equally"
        let splitType = SplitType(rawValue: splitTypeRaw) ?? .equally
        let dateTimestamp = data["Date"] as? Timestamp ?? Timestamp(date: Date())
        let date = dateTimestamp.dateValue()

        let participationsRef = db.collection("ExpenseParticipations")
        var participants: [Participant] = []
        var paymentDetails: [PaymentDetail] = []

        // Fetch payer
        let payerRef = data["PayerID"] as? DocumentReference

        let group = DispatchGroup()
        group.enter()

        payerRef?.getDocument { (payerDoc, error) in
            guard let payerData = payerDoc?.data(), let payerDoc = payerDoc else {
                print("Error fetching payer details: \(error?.localizedDescription ?? "Unknown error")")
                group.leave()
                return
            }

            let payer = Participant(
                Name: payerData["Name"] as? String ?? "Unknown",
                PhoneNumber: payerData["PhoneNumber"] as? String ?? "No Phone Number",
                Email: payerData["Email"] as? String ?? "No Email",
                friendshipID: "",
                id: payerDoc.documentID
            )

            // Fetch all participants and their payment details if necessary
            participationsRef.whereField("ExpenseID", isEqualTo: self.db.collection("Expense").document(documentID)).getDocuments { (snapshot, error) in
                guard let participantDocs = snapshot?.documents, error == nil else {
                    print("Error fetching participants: \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }

                for participantDoc in participantDocs {
                    group.enter()
                    let participantData = participantDoc.data()
                    print("payemntDetail \(participantData.self) ")
                    let paidAmount = participantData["PaidAmount"] as? Double ?? 0.0
//                    let owedPercentage = participantData["OwedPercentage"] as? Double ?? 0.0

                    if let participantRef = participantData["UserID"] as? DocumentReference {
                        participantRef.getDocument { (userDoc, error) in
                            if let userDoc = userDoc, userDoc.exists, let userData = userDoc.data() {
                                let participant = Participant(
                                    Name: userData["Name"] as? String ?? "Unknown",
                                    PhoneNumber: userData["PhoneNumber"] as? String ?? "No Phone Number",
                                    Email: userData["Email"] as? String ?? "No Email",
                                    friendshipID: participantDoc.documentID,
                                    id: userDoc.documentID
                                )
                                participants.append(participant)

                                    let paymentDetail = PaymentDetail(participantID: userDoc.documentID, amount: paidAmount)
                                    print(paymentDetail)
                                    paymentDetails.append(paymentDetail)
                                    print("paymentdetail: \(paymentDetail)")
                                
                                
                            }
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
                group.leave()
            }

            group.notify(queue: .main) {
                var expense = Expense(id: documentID,  description: description, date: date, totalAmount: totalAmount, splitType: splitType, participants: participants, payer: payer)
                    expense.paymentDetails = paymentDetails
                
                
                completion(expense)
            }
        }
    }
    
    
    
    func addExpense(description: String, totalAmount: Double, participants: [Participant], payer: Participant, splitType: SplitType, paymentDetails: [PaymentDetail],imageData: Data? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        let newExpenseRef = db.collection("Expense").document() // Note the collection name corrected to "Expenses"

        let payerRef = db.collection("User").document(payer.id) // Reference to the payer in the User collection
        var newExpenseData: [String: Any] = [
            "Description": description,
            "TotalAmount": totalAmount,
            "SplitType": splitType.rawValue,
            "Date": Timestamp(date: Date()),
            "PayerID": payerRef  // Storing the DocumentReference of the payer
        ]
        
        if let imageData = imageData {
                    newExpenseData["ImageData"] = imageData.base64EncodedString()  // Store image data as base64 string
                }


        // Set the data for the new expense
        newExpenseRef.setData(newExpenseData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let group = DispatchGroup()
            var errorOccurred: Error?

            // Add details for each participant in the ExpenseParticipations collection
            for detail in paymentDetails {
                group.enter()
                let participantRef = self.db.collection("User").document(detail.participantID) // Reference to the participant in the User collection
                let participationData: [String: Any] = [
                    "ExpenseID": newExpenseRef,  // Storing the DocumentReference of the expense
                    "UserID": participantRef,  // Storing the DocumentReference of the participant
                    "PaidAmount": detail.amount
                ]

                self.db.collection("ExpenseParticipations").addDocument(data: participationData) { error in
                    if let error = error {
                        errorOccurred = error
                    }
                    group.leave()
                }
            }

            // Notify the caller after all operations are completed
            group.notify(queue: .main) {
                if let error = errorOccurred {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }


    func deleteExpense(expenseID: String, completion: @escaping (Bool, Error?) -> Void) {
        // Reference to the expenses collection
        let expenseRef = db.collection("Expense").document(expenseID)

        // Delete all associated participations first
        deleteParticipations(for: expenseID) { [weak self] success, error in
            guard success, error == nil else {
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

    /// Helper function to delete all participations for an expense by ExpenseID
    private func deleteParticipations(for expenseID: String, completion: @escaping (Bool, Error?) -> Void) {
        // Reference to the ExpenseParticipations collection
        let participationsRef = db.collection("ExpenseParticipations")

        // Query for all participations linked to the specific ExpenseID
        let query = participationsRef.whereField("ExpenseID", isEqualTo: expenseID)

        // Get all documents from the query
        query.getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else {
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
    
    func fetchFriends(completion: @escaping () -> Void = {}) {
        guard let currentUserID = getCurrentUserID() else {
            print("User ID not available")
            completion()
            return
        }
        
        let userRef = db.collection("User").document(currentUserID)
        let fetchGroup = DispatchGroup()

        // Clear existing friends
        DispatchQueue.main.async {
            self.friends.removeAll()
        }

        // Fetch friendships where the current user is UserID1
        fetchGroup.enter()
        fetchFriendships(forUserRef: userRef, fromField: "UserID1", targetField: "UserID2") {
            fetchGroup.leave()
        }

        // Fetch friendships where the current user is UserID2
        fetchGroup.enter()
        fetchFriendships(forUserRef: userRef, fromField: "UserID2", targetField: "UserID1") {
            fetchGroup.leave()
        }
        
        fetchGroup.notify(queue: .main) {
            completion()
        }
    }

    private func fetchFriendships(forUserRef userRef: DocumentReference, fromField: String, targetField: String, completion: @escaping () -> Void = {}) {
        let friendsRef = db.collection("Friends")
        friendsRef.whereField(fromField, isEqualTo: userRef).getDocuments { [weak self] querySnapshot, error in
            if let error = error {
                print("Error fetching friendships: \(error.localizedDescription)")
                completion()
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No friendships found")
                completion()
                return
            }

            for document in documents {
                let friendshipID = document.documentID
                self?.processFriendship(document, targetField: targetField, friendshipID: friendshipID)
            }
            completion()
        }
    }

    private func processFriendship(_ document: QueryDocumentSnapshot, targetField: String, friendshipID: String) {
        guard let friendRef = document.get(targetField) as? DocumentReference else { return }

        friendRef.getDocument { [weak self] (userDoc, error) in
               if let userDoc = userDoc, userDoc.exists, let userData = userDoc.data() {
                   // Extracting values safely using optional casting and providing default values
                   let id = userDoc.documentID
                   let name = userData["Name"] as? String ?? "Unknown"
                   let phoneNumber = userData["PhoneNumber"] as? String ?? "No Phone Number"
                   let email = userData["Email"] as? String ?? "No Email"
                   
                   // Constructing the Participant instance
                   let participant = Participant(Name: name,
                                                 PhoneNumber: phoneNumber,
                                                 Email: email,
                                                 friendshipID: friendshipID,
                                                 id: id)
                   
                   // Now we have a valid Participant instance, we can add it to the friends list
                   DispatchQueue.main.async {
                       self?.friends.append(participant)
                   }
               } else if let error = error {
                   print("Error fetching participant details: \(error.localizedDescription)")
               }
           }
    }
    
    
    // Functions used for searching and adding friends
    func searchUser(phoneNumberOrEmail: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let usersRef = db.collection("User")

        // First, attempt to find the user by email
        usersRef.whereField("Email", isEqualTo: phoneNumberOrEmail).getDocuments { [weak self] querySnapshot, error in
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                let userDoc = documents.first!
                // If found by email, add the friend
                self?.addFriendship(with: userDoc.documentID) { result in
                    switch result {
                    case .success(_):
                        let id = userDoc.documentID
                        let userData = userDoc.data()
                        let name = userData["Name"] as? String ?? "Unknown"
                        let phoneNumber = userData["PhoneNumber"] as? String ?? "No Phone Number"
                        let email = userData["Email"] as? String ?? "No Email"
                        
                        let participant = Participant(Name: name, PhoneNumber: phoneNumber, Email: email, friendshipID: userDoc.documentID, id: id)
                        
                        // Append the friend to the local friends array
                        DispatchQueue.main.async {
                            self?.friends.append(participant)
                            completion(.success(true))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                return
            } else if error == nil {
                // If not found by email and no error, search by phone number
                usersRef.whereField("PhoneNumber", isEqualTo: phoneNumberOrEmail).getDocuments { [weak self] querySnapshot, error in
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        // If found by phone number, add the friend
                        self?.addFriendship(with: documents.first!.documentID, completion: completion)
                    } else if let error = error {
                        // Handle error from phoneNumber query
                        completion(.failure(error))
                    } else {
                        // No user found by phone number either
                        completion(.success(false))
                    }
                }
            } else if let error = error {
                // Handle error from email query
                completion(.failure(error))
            }
        }
    }


    func addFriendship(with friendUserID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let currentUserID = getCurrentUserID() else {
            completion(.failure(NSError(domain: "DataStoreError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch current user ID."])))
            return
        }

        let usersRef = db.collection("User")
        let currentUserRef = usersRef.document(currentUserID)
        let friendUserRef = usersRef.document(friendUserID)

        let friendshipData: [String: Any] = [
            "UserID1": currentUserRef,
            "UserID2": friendUserRef,
            "FriendshipDate": Timestamp(date: Date())
        ]

        db.collection("Friends").addDocument(data: friendshipData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    
    
    func deleteFriend(friendshipID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let friendsRef = db.collection("Friends")
        
        // Fetching the specific document to delete
        let friendshipRef = friendsRef.document(friendshipID)
        
        // Deleting the document
        friendshipRef.delete { error in
            if let error = error {
                print("Error deleting friendship: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                // Optionally, update any local data structures
                DispatchQueue.main.async {
                    self.friends.removeAll { $0.friendshipID == friendshipID }
                }
                print("Friendship deleted successfully.")
                completion(.success(true))
            }
        }
    }
    
    
    
    
    



            // MARK: - Group Operation (fetch, add, delete, update)
            
            
        }
    

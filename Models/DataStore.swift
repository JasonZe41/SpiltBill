//
//  Datastore.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//

import Foundation
#if os(iOS)
import FirebaseFirestore
import Firebase
import FirebaseStorage
#endif
import WatchConnectivity

/// DataStore is a class that handles data operations and synchronization with Firestore and WatchConnectivity.
class DataStore: NSObject, ObservableObject, WCSessionDelegate {
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage()

    @Published var expenses: [Expense] = []
    @Published var friends: [Participant] = []
    @Published var currentUser: Participant?

    /// Initializes the `DataStore` instance and fetches the groups, expenses, and friends from Firestore
    override init() {
        super.init()
        initializeWatchConnectivity()
        fetchDataAndSendToWatch()
    }
    
    /// Initializes WatchConnectivity if supported.
    private func initializeWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    /// Fetches current user, expenses, and friends, then sends the data to the watch if available.
    private func fetchDataAndSendToWatch() {
        fetchCurrentUser { user in
            DispatchQueue.main.async {
                self.currentUser = user
                self.checkAndSendDataToWatch()
            }
        }
        fetchExpenses { fetchedExpenses in
            DispatchQueue.main.async {
                self.expenses = fetchedExpenses
                self.checkAndSendDataToWatch()
            }
        }
        fetchFriends {
            self.checkAndSendDataToWatch()
        }
    }
    
    /// Checks if the WatchConnectivity session is activated and sends the data to the watch if all data is available.
    private func checkAndSendDataToWatch() {
        guard WCSession.default.activationState == .activated else {
            print("WCSession is not activated yet.")
            return
        }

        // Ensure all data is fetched before sending
        guard !expenses.isEmpty, !friends.isEmpty, let currentUser = currentUser else {
            print("Data is not ready yet. Expenses: \(expenses.count), Friends: \(friends.count), Current User: \(String(describing: currentUser))")
            return
        }

        sendDataToWatch()
    }
    
    /// Retrieves the current user ID from UserDefaults.
    private func getCurrentUserID() -> String? {
        UserDefaults.standard.string(forKey: "userId")
    }
    
    /// Logs out the current user by clearing their user defaults and setting the currentUser property to nil.
    func logout() {
        UserDefaults.standard.removeObject(forKey: "userId")
        currentUser = nil
    }
    
    /// Fetches the current user's information from Firestore.
    /// - Parameter completion: A closure that gets called with the fetched Participant or nil if an error occurred.
    func fetchCurrentUser(completion: @escaping (Participant?) -> Void) {
        guard let userID = getCurrentUserID() else {
            print("User ID not available")
            completion(nil)
            return
        }

        let userRef = db.collection("User").document(userID)
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                let participant = Participant(
                    id: document.documentID,
                    Name: data?["Name"] as? String ?? "Unknown",
                    PhoneNumber: data?["PhoneNumber"] as? String ?? "No Phone Number",
                    Email: data?["Email"] as? String ?? "No Email",
                    friendshipID: "",
                    owedAmount: 0
                )

                completion(participant)
            } else {
                print("Document does not exist: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
    
    // MARK: - Expenses Operation (fetch, add, delete, or update)

    /// Fetches all expenses associated with the current user.
    /// - Parameter completion: A closure that gets called with an array of fetched Expense objects.
    func fetchExpenses(completion: @escaping ([Expense]) -> Void) {
        guard let currentUserID = getCurrentUserID() else {
            print("User ID not available")
            completion([])
            return
        }

        let userRef = db.collection("User").document(currentUserID)
        let participationsRef = db.collection("ExpenseParticipations")
        
        // Looking through ExpenseParticipations collection to find all expenses involving the current user
        participationsRef.whereField("UserID", isEqualTo: userRef).getDocuments { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents, !documents.isEmpty, error == nil else {
                print("No expense participations found or error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            let expenseIDs = documents.compactMap { ($0.data()["ExpenseID"] as? DocumentReference)?.documentID }
            self?.fetchExpenseDetails(fromIDs: expenseIDs, completion: completion)
        }
        
        self.sendDataToWatch()
    }

    /// Fetches details for a list of expense IDs.
    /// - Parameters:
    ///   - expenseIDs: An array of expense IDs to fetch details for.
    ///   - completion: A closure that gets called with an array of fetched Expense objects.
    private func fetchExpenseDetails(fromIDs expenseIDs: [String], completion: @escaping ([Expense]) -> Void) {
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

    /// Constructs an Expense object from Firestore data.
    /// - Parameters:
    ///   - data: A dictionary containing the expense data from Firestore.
    ///   - documentID: The document ID of the expense.
    ///   - completion: A closure that gets called with the constructed Expense object.
    private func constructExpense(from data: [String: Any], documentID: String, completion: @escaping (Expense) -> Void) {
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
                id: payerDoc.documentID,
                Name: payerData["Name"] as? String ?? "Unknown",
                PhoneNumber: payerData["PhoneNumber"] as? String ?? "No Phone Number",
                Email: payerData["Email"] as? String ?? "No Email",
                friendshipID: "",
                owedAmount: 0
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
                    let paidAmount = participantData["PaidAmount"] as? Double ?? 0.0

                    if let participantRef = participantData["UserID"] as? DocumentReference {
                        participantRef.getDocument { (userDoc, error) in
                            if let userDoc = userDoc, userDoc.exists, let userData = userDoc.data() {
                                let participant = Participant(
                                    id: userDoc.documentID,
                                    Name: userData["Name"] as? String ?? "Unknown",
                                    PhoneNumber: userData["PhoneNumber"] as? String ?? "No Phone Number",
                                    Email: userData["Email"] as? String ?? "No Email",
                                    friendshipID: participantDoc.documentID,
                                    owedAmount: 0
                                )

                                participants.append(participant)

                                let paymentDetail = PaymentDetail(participantID: userDoc.documentID, amount: paidAmount)
                                paymentDetails.append(paymentDetail)
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
                var expense = Expense(id: documentID, description: description, date: date, totalAmount: totalAmount, splitType: splitType, participants: participants, payer: payer)
                expense.paymentDetails = paymentDetails
                completion(expense)
            }
        }
    }
    
    /// Uploads an image to Firebase Storage.
    /// - Parameters:
    ///   - image: The UIImage to upload.
    ///   - completion: A closure that gets called with the result of the upload, either a URL or an Error.
    func uploadImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data."])))
            return
        }

        let storageRef = storage.reference().child("receipt_images/\(UUID().uuidString).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let url = url {
                    completion(.success(url))
                } else {
                    completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL."])))
                }
            }
        }
    }
    
    /// Adds a new expense to Firestore.
    /// - Parameters:
    ///   - description: The description of the expense.
    ///   - totalAmount: The total amount of the expense.
    ///   - participants: A list of participants involved in the expense.
    ///   - payer: The participant who paid for the expense.
    ///   - splitType: The type of split for the expense.
    ///   - paymentDetails: A list of payment details for the expense.
    ///   - imageURL: An optional URL for the receipt image.
    ///   - completion: A closure that gets called with the result of the operation, either success or failure.
    func addExpense(description: String, totalAmount: Double, participants: [Participant], payer: Participant, splitType: SplitType, paymentDetails: [PaymentDetail], imageURL: URL?, completion: @escaping (Result<Void, Error>) -> Void) {
        let newExpenseRef = db.collection("Expense").document()
        let payerRef = db.collection("User").document(payer.id)

        var newExpenseData: [String: Any] = [
            "Description": description,
            "TotalAmount": totalAmount,
            "SplitType": splitType.rawValue,
            "Date": Timestamp(date: Date()),
            "PayerID": payerRef
        ]

        if let imageURL = imageURL {
            newExpenseData["ImageURL"] = imageURL.absoluteString
        }

        newExpenseRef.setData(newExpenseData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let group = DispatchGroup()
            var errorOccurred: Error?

            for detail in paymentDetails {
                group.enter()
                let participantRef = self.db.collection("User").document(detail.participantID)
                let participationData: [String: Any] = [
                    "ExpenseID": newExpenseRef,
                    "UserID": participantRef,
                    "PaidAmount": detail.amount
                ]

                self.db.collection("ExpenseParticipations").addDocument(data: participationData) { error in
                    if let error = error {
                        errorOccurred = error
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                if let error = errorOccurred {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    /// Deletes an expense from Firestore.
    /// - Parameters:
    ///   - expenseID: The ID of the expense to delete.
    ///   - completion: A closure that gets called with the result of the operation, either success or failure.
    func deleteExpense(expenseID: String, completion: @escaping (Bool, Error?) -> Void) {
        let expenseRef = db.collection("Expense").document(expenseID)

        deleteParticipations(for: expenseID) { [weak self] success, error in
            guard success, error == nil else {
                completion(false, error)
                return
            }

            expenseRef.delete { error in
                if let error = error {
                    completion(false, error)
                } else {
                    DispatchQueue.main.async {
                        self?.expenses.removeAll { $0.id == expenseID }
                        completion(true, nil)
                    }
                }
            }
        }
    }

    /// Deletes all participations for a specific expense.
    /// - Parameters:
    ///   - expenseID: The ID of the expense.
    ///   - completion: A closure that gets called with the result of the operation, either success or failure.
    private func deleteParticipations(for expenseID: String, completion: @escaping (Bool, Error?) -> Void) {
        let participationsRef = db.collection("ExpenseParticipations")

        let query = participationsRef.whereField("ExpenseID", isEqualTo: expenseID)

        query.getDocuments { (snapshot, error) in
            guard let documents = snapshot?.documents, error == nil else {
                completion(false, error)
                return
            }

            let batch = self.db.batch()
            documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }

            batch.commit { error in
                if let error = error {
                    completion(false, error)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    // MARK: - Friends Operation (fetch, add, delete)

    /// Fetches the list of friends for the current user from Firestore.
    /// - Parameter completion: A closure that gets called when the fetching is complete.
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
        self.sendDataToWatch()
    }

    /// Fetches friendship documents for a given user reference.
    /// - Parameters:
    ///   - userRef: The DocumentReference of the user.
    ///   - fromField: The field in the friendship document that holds the user reference.
    ///   - targetField: The field in the friendship document that holds the friend's reference.
    ///   - completion: A closure that gets called when the fetching is complete.
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

    /// Processes a friendship document to extract friend details.
    /// - Parameters:
    ///   - document: The friendship document snapshot.
    ///   - targetField: The field in the friendship document that holds the friend's reference.
    ///   - friendshipID: The ID of the friendship document.
    private func processFriendship(_ document: QueryDocumentSnapshot, targetField: String, friendshipID: String) {
        guard let friendRef = document.get(targetField) as? DocumentReference else { return }

        friendRef.getDocument { [weak self] (userDoc, error) in
            if let userDoc = userDoc, userDoc.exists, let userData = userDoc.data() {
                let id = userDoc.documentID
                let name = userData["Name"] as? String ?? "Unknown"
                let phoneNumber = userData["PhoneNumber"] as? String ?? "No Phone Number"
                let email = userData["Email"] as? String ?? "No Email"
                
                let participant = Participant(
                    id: id,
                    Name: name,
                    PhoneNumber: phoneNumber,
                    Email: email,
                    friendshipID: friendshipID,
                    owedAmount: 0
                )

                DispatchQueue.main.async {
                    self?.friends.append(participant)
                }
            } else if let error = error {
                print("Error fetching participant details: \(error.localizedDescription)")
            }
        }
    }

    /// Searches for a user by phone number or email and adds them as a friend if found.
    /// - Parameters:
    ///   - phoneNumberOrEmail: The phone number or email of the user to search for.
    ///   - completion: A closure that gets called with the result of the operation, either success or failure.
    func searchUser(phoneNumberOrEmail: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let usersRef = db.collection("User")

        usersRef.whereField("Email", isEqualTo: phoneNumberOrEmail).getDocuments { [weak self] querySnapshot, error in
            if let documents = querySnapshot?.documents, !documents.isEmpty {
                let userDoc = documents.first!
                self?.addFriendship(with: userDoc.documentID) { result in
                    switch result {
                    case .success(_):
                        let id = userDoc.documentID
                        let userData = userDoc.data()
                        let name = userData["Name"] as? String ?? "Unknown"
                        let phoneNumber = userData["PhoneNumber"] as? String ?? "No Phone Number"
                        let email = userData["Email"] as? String ?? "No Email"
                        
                        let participant = Participant(
                            id: id,
                            Name: name,
                            PhoneNumber: phoneNumber,
                            Email: email,
                            friendshipID: userDoc.documentID
                        )
                        
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
                usersRef.whereField("PhoneNumber", isEqualTo: phoneNumberOrEmail).getDocuments { [weak self] querySnapshot, error in
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        self?.addFriendship(with: documents.first!.documentID, completion: completion)
                    } else if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(false))
                    }
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }

    /// Adds a friendship document to Firestore for the current user and the specified friend.
    /// - Parameters:
    ///   - friendUserID: The ID of the user to add as a friend.
    ///   - completion: A closure that gets called with the result of the operation, either success or failure.
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
    
    /// Deletes a friendship document from Firestore.
    /// - Parameters:
    ///   - friendshipID: The ID of the friendship document to delete.
    ///   - completion: A closure that gets called with the result of the operation, either success or failure.
    func deleteFriend(friendshipID: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let friendsRef = db.collection("Friends")
        let friendshipRef = friendsRef.document(friendshipID)
        
        friendshipRef.delete { error in
            if let error = error {
                print("Error deleting friendship: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                DispatchQueue.main.async {
                    self.friends.removeAll { $0.friendshipID == friendshipID }
                }
                print("Friendship deleted successfully.")
                completion(.success(true))
            }
        }
    }

    /// Sends the current user's data, expenses, and friends to the watch.
    private func sendDataToWatch() {
        guard WCSession.default.activationState == .activated else {
            print("WCSession is not activated")
            return
        }

        print("Expenses: \(expenses)")
        print("Friends: \(friends)")
        print("Current User: \(String(describing: currentUser))")

        let expensesData = try? JSONEncoder().encode(expenses)
        let friendsData = try? JSONEncoder().encode(friends)
        let currentUserData = try? JSONEncoder().encode(currentUser)

        var message: [String: Any] = [:]
        if let expensesData = expensesData {
            print("Encoded expenses data size: \(expensesData.count) bytes")
            message["expenses"] = expensesData
        }
        if let friendsData = friendsData {
            print("Encoded friends data size: \(friendsData.count) bytes")
            message["friends"] = friendsData
        }
        if let currentUserData = currentUserData {
            print("Encoded currentUser data size: \(currentUserData.count) bytes")
            message["currentUser"] = currentUserData
        }

        do {
            try WCSession.default.updateApplicationContext(message)
            print("Successfully sent application context to watch.")
        } catch {
            print("Failed to send application context to watch: \(error.localizedDescription)")
        }
    }

    // MARK: - WCSessionDelegate methods

    /// Called when the WatchConnectivity session activation completes.
    /// - Parameters:
    ///   - session: The WatchConnectivity session.
    ///   - activationState: The state of the session activation.
    ///   - error: An optional error if the activation failed.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
            sendDataToWatch() // Send data after session activation
        }
    }

    /// Called when the WatchConnectivity session becomes inactive.
    /// - Parameter session: The WatchConnectivity session.
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session inactivity
    }
    
    /// Called when the WatchConnectivity session deactivates.
    /// - Parameter session: The WatchConnectivity session.
    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation
        session.activate()
    }

}

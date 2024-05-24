//
//  User.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//

import Foundation

/// A struct representing a participant in the application. This includes details like ID, name, phone number, email, friendship ID, and owed amount.
struct Participant: Identifiable, Codable, Equatable {
    var id: String
    var Name: String
    var PhoneNumber: String
    var Email: String
    var friendshipID: String
    var owedAmount: Double = 0

    /// Initializes a Participant instance.
    /// - Parameters:
    ///   - id: The unique identifier for the participant.
    ///   - Name: The name of the participant.
    ///   - PhoneNumber: The phone number of the participant.
    ///   - Email: The email address of the participant.
    ///   - friendshipID: The friendship ID associated with the participant.
    ///   - owedAmount: The amount the participant owes. Defaults to 0.
    init(id: String, Name: String, PhoneNumber: String, Email: String, friendshipID: String, owedAmount: Double = 0) {
        self.id = id
        self.Name = Name
        self.PhoneNumber = PhoneNumber
        self.Email = Email
        self.friendshipID = friendshipID
        self.owedAmount = owedAmount
    }

    /// Initializes a Participant instance from a dictionary.
    /// - Parameter dictionary: A dictionary containing participant details.
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.Name = dictionary["Name"] as? String ?? ""
        self.PhoneNumber = dictionary["PhoneNumber"] as? String ?? ""
        self.Email = dictionary["Email"] as? String ?? ""
        self.friendshipID = dictionary["friendshipID"] as? String ?? ""
        self.owedAmount = dictionary["owedAmount"] as? Double ?? 0
    }

    /// Converts the Participant instance to a dictionary.
    /// - Returns: A dictionary representation of the Participant instance.
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "Name": Name,
            "PhoneNumber": PhoneNumber,
            "Email": Email,
            "friendshipID": friendshipID,
            "owedAmount": owedAmount
        ]
    }
}

/// A struct representing payment details for an expense. This includes the participant ID and the amount they owe.
struct PaymentDetail: Codable {
    var participantID: String
    var amount: Double

    /// Initializes a PaymentDetail instance.
    /// - Parameters:
    ///   - participantID: The unique identifier for the participant.
    ///   - amount: The amount the participant owes.
    init(participantID: String, amount: Double) {
        self.participantID = participantID
        self.amount = amount
    }

    /// Initializes a PaymentDetail instance from a dictionary.
    /// - Parameter dictionary: A dictionary containing payment details.
    init(dictionary: [String: Any]) {
        self.participantID = dictionary["participantID"] as? String ?? ""
        self.amount = dictionary["amount"] as? Double ?? 0.0
    }

    /// Converts the PaymentDetail instance to a dictionary.
    /// - Returns: A dictionary representation of the PaymentDetail instance.
    func toDictionary() -> [String: Any] {
        return [
            "participantID": participantID,
            "amount": amount
        ]
    }
}

/// An enum representing the different types of splits for an expense.
enum SplitType: String, Codable, CaseIterable {
    case equally = "Equally"
    case percentage = "Percentage"
    case byAmount = "By Amount"
}

/// A struct representing an expense in the application. This includes details like ID, description, date, total amount, split type, participants, payer, payment details, and image data.
struct Expense: Codable, Identifiable {
    var id: String
    var description: String
    var date: Date
    var totalAmount: Double
    var splitType: SplitType
    var participants: [Participant]
    var payer: Participant
    var paymentDetails: [PaymentDetail]?
    var imageData: Data?

    /// Initializes an Expense instance.
    /// - Parameters:
    ///   - id: The unique identifier for the expense.
    ///   - description: The description of the expense.
    ///   - date: The date of the expense.
    ///   - totalAmount: The total amount of the expense.
    ///   - splitType: The type of split for the expense.
    ///   - participants: A list of participants involved in the expense.
    ///   - payer: The participant who paid for the expense.
    ///   - paymentDetails: A list of payment details for the expense. Defaults to nil.
    ///   - imageData: Optional image data associated with the expense. Defaults to nil.
    init(id: String, description: String, date: Date, totalAmount: Double, splitType: SplitType, participants: [Participant], payer: Participant, paymentDetails: [PaymentDetail]? = nil, imageData: Data? = nil) {
        self.id = id
        self.description = description
        self.date = date
        self.totalAmount = totalAmount
        self.splitType = splitType
        self.participants = participants
        self.payer = payer
        self.paymentDetails = paymentDetails
        self.imageData = imageData
    }

    /// Initializes an Expense instance from a dictionary.
    /// - Parameter dictionary: A dictionary containing expense details.
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
        self.totalAmount = dictionary["totalAmount"] as? Double ?? 0.0
        self.payer = Participant(dictionary: dictionary["payer"] as? [String: Any] ?? [:])
        self.participants = (dictionary["participants"] as? [[String: Any]] ?? []).map { Participant(dictionary: $0) }
        self.date = Date(timeIntervalSince1970: dictionary["date"] as? TimeInterval ?? 0)
        self.splitType = SplitType(rawValue: dictionary["splitType"] as? String ?? "") ?? .equally
        self.paymentDetails = (dictionary["paymentDetails"] as? [[String: Any]] ?? []).map { PaymentDetail(dictionary: $0) }
        if let imageDataString = dictionary["imageData"] as? String, let imageData = Data(base64Encoded: imageDataString) {
            self.imageData = imageData
        }
    }

    /// Converts the Expense instance to a dictionary.
    /// - Returns: A dictionary representation of the Expense instance.
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "description": description,
            "totalAmount": totalAmount,
            "payer": payer.toDictionary(),
            "participants": participants.map { $0.toDictionary() },
            "date": date.timeIntervalSince1970,
            "splitType": splitType.rawValue,
            "paymentDetails": paymentDetails?.map { $0.toDictionary() },
            "imageData": imageData?.base64EncodedString() ?? ""
        ]
    }
}

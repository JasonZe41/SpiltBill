//
//  User.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//
import Foundation
struct Participant: Identifiable, Codable, Equatable {
    var id: String
    var Name: String
    var PhoneNumber: String
    var Email: String
    var friendshipID: String
    var owedAmount: Double = 0
    
    init(id: String, Name: String, PhoneNumber: String, Email: String, friendshipID: String, owedAmount: Double = 0) {
        self.id = id
        self.Name = Name
        self.PhoneNumber = PhoneNumber
        self.Email = Email
        self.friendshipID = friendshipID
        self.owedAmount = owedAmount
    }

    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.Name = dictionary["Name"] as? String ?? ""
        self.PhoneNumber = dictionary["PhoneNumber"] as? String ?? ""
        self.Email = dictionary["Email"] as? String ?? ""
        self.friendshipID = dictionary["friendshipID"] as? String ?? ""
        self.owedAmount = dictionary["owedAmount"] as? Double ?? 0
    }
    
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


struct PaymentDetail: Codable {
    var participantID: String
    var amount: Double
    
    
    init(participantID: String, amount: Double){
        self.participantID = participantID
        self.amount = amount
    }
    
    
    init(dictionary: [String: Any]) {
        self.participantID = dictionary["participantID"] as? String ?? ""
        self.amount = dictionary["amount"] as? Double ?? 0.0
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "participantID": participantID,
            "amount": amount
        ]
    }
}

enum SplitType: String, Codable, CaseIterable {
    case equally = "Equally"
    case percentage = "Percentage"
    case byAmount = "By Amount"
}

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

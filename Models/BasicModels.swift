//
//  User.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//

import Foundation
import SwiftUI

/// Represents an individual participant in an expense. Conforms to `Hashable` for use in collections that require unique identification.
struct Participant: Identifiable, Codable {
    /// The name of the participant.
       var Name: String
       
       var id: String // firestore document ID of the userID
       
    /// The phone number of the participant.
       var PhoneNumber: String
       
    /// The email of the participant
       var Email: String
    
    ///  firestore friendship document ID of current participant
     var friendshipID: String
    
}


enum SplitType: String, Codable {
    case equally, percentage, byAmount
}


struct Expense: Codable, Identifiable{
   
    ///  firestore expense table ID of current participant
    var id: String
    
    var groupID: String  // Reference to a Group
    
    var description: String

    var date: Date
    
    var totalAmount: Double
    
    var splitType: SplitType
    

    /// reocrd which participant is involved, or another choice is that only reocrd the id
    var participants: [Participant]
    
}

struct Group:Codable, Identifiable{
    var id: String
    var groupName: String
    var description: String
    var creationDate: Date
    var expenses: [Expense]
    var participants: [Participant]
}



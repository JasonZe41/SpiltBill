//
//  WatchDataStore.swift
//  SpiltBillWatch Watch App
//
//  Created by Jason Ze on 2024/5/24.
//
import Foundation
import WatchConnectivity
import SwiftUI

class WatchDataStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var expenses: [Expense] = []
    @Published var friends: [Participant] = []
    @Published var currentUser: Participant?

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received application context: \(applicationContext)")
        DispatchQueue.main.async {
            if let expensesData = applicationContext["expenses"] as? Data {
                print("Received expenses data: \(expensesData.count) bytes")
                do {
                    self.expenses = try JSONDecoder().decode([Expense].self, from: expensesData)
                    print("Decoded expenses data: \(self.expenses)")
                } catch {
                    print("Failed to decode expenses: \(error.localizedDescription)")
                }
            }
            if let friendsData = applicationContext["friends"] as? Data {
                print("Received friends data: \(friendsData.count) bytes")
                do {
                    self.friends = try JSONDecoder().decode([Participant].self, from: friendsData)
                    print("Decoded friends data: \(self.friends)")
                } catch {
                    print("Failed to decode friends: \(error.localizedDescription)")
                }
            }
            if let currentUserData = applicationContext["currentUser"] as? Data {
                print("Received currentUser data: \(currentUserData.count) bytes")
                do {
                    self.currentUser = try JSONDecoder().decode(Participant.self, from: currentUserData)
                    print("Decoded currentUser data: \(String(describing: self.currentUser))")
                } catch {
                    print("Failed to decode currentUser: \(error.localizedDescription)")
                }
            }
        }
    }
}

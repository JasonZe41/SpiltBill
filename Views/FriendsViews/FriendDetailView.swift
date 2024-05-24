//
//  FriendDetailView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/13.
//
import SwiftUI

/// A SwiftUI view that displays the details of a friend's expenses.
struct FriendDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    var friend: Participant

    var body: some View {
        VStack {
            // List of shared expenses between the current user and the friend.
            List {
                ForEach(sharedExpenses(), id: \.id) { expense in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(expense.description)
                            .font(.headline)
                        HStack {
                            Text("Amount:")
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(expense.totalAmount, specifier: "%.2f")")
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("Paid by:")
                                .fontWeight(.bold)
                            Spacer()
                            Text(expense.payer.Name)
                                .foregroundColor(.gray)
                        }
                        Divider()
                        Text("Participants:")
                            .fontWeight(.bold)
                        // Display only the relevant payment details.
                        ForEach(expense.paymentDetails?.filter { $0.participantID == friend.id || $0.participantID == dataStore.currentUser?.id } ?? [], id: \.participantID) { detail in
                            Text("\(dataStore.participantName(for: detail.participantID)): \(detail.amount, specifier: "%.2f")")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("\(friend.Name)'s Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Balance: \(calculateNetBalance(), specifier: "%.2f")")
                        .font(.headline)
                }
            }
        }
    }

    /// Returns a list of expenses shared between the current user and the friend.
    private func sharedExpenses() -> [Expense] {
        guard let currentUserID = dataStore.currentUser?.id else { return [] }

        return dataStore.expenses.filter { expense in
            let isCurrentUserPayer = expense.payer.id == currentUserID
            let isFriendPayer = expense.payer.id == friend.id
            let includesFriendAsParticipant = expense.participants.contains { $0.id == friend.id }
            let includesCurrentUserAsParticipant = expense.participants.contains { $0.id == currentUserID }

            return (isCurrentUserPayer && includesFriendAsParticipant) || (isFriendPayer && includesCurrentUserAsParticipant)
        }
    }

    /// Calculates the net balance between the current user and the friend.
    private func calculateNetBalance() -> Double {
        guard let currentUserID = dataStore.currentUser?.id else { return 0.0 }

        return sharedExpenses().reduce(0) { balance, expense in
            let paymentDetails = expense.paymentDetails ?? []
            let isCurrentUserPayer = expense.payer.id == currentUserID

            let friendDetailAmount = paymentDetails.first { $0.participantID == friend.id }?.amount ?? 0.0
            let currentUserDetailAmount = paymentDetails.first { $0.participantID == currentUserID }?.amount ?? 0.0

            if isCurrentUserPayer {
                return balance + friendDetailAmount
            } else {
                return balance - currentUserDetailAmount
            }
        }
    }
}

extension DataStore {
    /// Returns the name of a participant given their ID.
    /// - Parameter id: The ID of the participant.
    /// - Returns: The name of the participant or "Unknown" if not found.
    func participantName(for id: String) -> String {
        friends.first { $0.id == id }?.Name ?? "Unknown"
    }
}

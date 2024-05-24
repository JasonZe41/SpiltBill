//  FriendDetailView.swift
//  SpiltBillWatch Watch App
//
//  Created by Jason Ze on 2024/5/24.
//
import SwiftUI

struct FriendDetailView: View {
    var friend: Participant?
    @EnvironmentObject var dataStore: WatchDataStore

    var sharedExpenses: [Expense] {
        guard let friend = friend else { return [] }
        return dataStore.expenses.filter { expense in
            expense.participants.contains(where: { $0.id == friend.id })
        }
    }

    var totalOwedAmount: Double {
        guard let friend = friend else { return 0.0 }
        return sharedExpenses.reduce(0) { total, expense in
            total + (expense.paymentDetails?.first { $0.participantID == friend.id }?.amount ?? 0)
        }
    }

    var body: some View {
        ScrollView {
            VStack {
                if let friend = friend {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(friend.Name)
                            .font(.headline)
                        Text(friend.Email)
                            .font(.subheadline)
                        Text(friend.PhoneNumber)
                            .font(.subheadline)
                        
                        Text("Total Owed: \(totalOwedAmount, specifier: "%.2f")")
                            .font(.headline)
                            .padding(.vertical, 10)

                        Divider()

                        Text("Shared Expenses")
                            .font(.headline)
                            .padding(.vertical, 5)

                        ForEach(sharedExpenses, id: \.id) { expense in
                            VStack(alignment: .leading) {
                                Text(expense.description)
                                    .font(.headline)
                                Text("Amount: \(expense.totalAmount, specifier: "%.2f")")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding()
                } else {
                    VStack {
                        Text("Friend details not available.")
                            .foregroundColor(.red)
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Friend Detail")
        }
    }
}

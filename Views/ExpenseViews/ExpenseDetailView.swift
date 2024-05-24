//
//  ExpenseDetailView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/5/13.
//

import SwiftUI

/// A SwiftUI view to display the details of a specific expense.
struct ExpenseDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    var expenseId: String

    /// Retrieves the expense object based on the provided expense ID.
    private var expense: Expense? {
        dataStore.expenses.first { $0.id == expenseId }
    }

    var body: some View {
        List {
            if let expense = expense {
                // Display expense details and participants sections.
                expenseDetailsSection(expense: expense)
                participantsSection(expense: expense)
            } else {
                // Display an error message if the expense details are not found.
                Text("Expense details not found.")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Expense Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// A view builder method to display the expense details section.
    /// - Parameter expense: The expense object containing details to display.
    @ViewBuilder
    private func expenseDetailsSection(expense: Expense) -> some View {
        Section(header: Text("Expense Details").font(.headline)) {
            HStack {
                Text("Description:")
                    .fontWeight(.bold)
                Spacer()
                Text(expense.description)
                    .foregroundColor(.gray)
            }
            HStack {
                Text("Total Amount:")
                    .fontWeight(.bold)
                Spacer()
                Text(String(format: "%.2f", expense.totalAmount))
                    .foregroundColor(.gray)
            }
            HStack {
                Text("Payer:")
                    .fontWeight(.bold)
                Spacer()
                Text(expense.payer.Name)
                    .foregroundColor(.gray)
            }
            HStack {
                Text("Date:")
                    .fontWeight(.bold)
                Spacer()
                Text(expense.date, formatter: dateFormatter)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
    }

    /// A view builder method to display the participants section.
    /// - Parameter expense: The expense object containing participants details.
    @ViewBuilder
    private func participantsSection(expense: Expense) -> some View {
        Section(header: Text("Participants").font(.headline)) {
            ForEach(expense.paymentDetails ?? [], id: \.participantID) { detail in
                if let participant = expense.participants.first(where: { $0.id == detail.participantID }) {
                    ParticipantDetailRow(participant: participant, amount: detail.amount)
                } else {
                    // Display an error message if participant details are not available.
                    Text("Participant details not available.")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 10)
    }

    /// Date formatter to format the date display.
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

/// A SwiftUI view to display a participant's details in the expense.
struct ParticipantDetailRow: View {
    var participant: Participant
    var amount: Double

    var body: some View {
        HStack {
            Text(participant.Name)
                .fontWeight(.bold)
            Spacer()
            Text(String(format: "%.2f", amount))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 5)
    }
}

//
//  ExpenseDetailView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/5/13.
//
import SwiftUI

struct ExpenseDetailView: View {
    @EnvironmentObject var dataStore: DataStore
    var expenseId: String

    private var expense: Expense? {
        dataStore.expenses.first { $0.id == expenseId }
    }

    var body: some View {
        List {
            if let expense = expense {
                expenseDetailsSection(expense: expense)
                participantsSection(expense: expense)
            } else {
                Text("Expense details not found.")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Expense Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

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

    @ViewBuilder
    private func participantsSection(expense: Expense) -> some View {
        Section(header: Text("Participants").font(.headline)) {
            ForEach(expense.paymentDetails ?? [], id: \.participantID) { detail in
                if let participant = expense.participants.first(where: { $0.id == detail.participantID }) {
                    ParticipantDetailRow(participant: participant, amount: detail.amount)
                } else {
                    Text("Participant details not available.")
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 10)
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

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

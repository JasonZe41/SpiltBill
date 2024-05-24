//
//  ExpenseDetailView.swift
//  SpiltBillWatch Watch App
//
//  Created by Jason Ze on 2024/5/24.
//

import SwiftUI

struct ExpenseDetailView: View {
    var expense: Expense?

    var body: some View {
        VStack {
            if let expense = expense {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(expense.description)
                            .font(.headline)
                            .padding(.bottom, 5)
                        
                        Text("Total: \(expense.totalAmount, specifier: "%.2f")")
                            .font(.subheadline)
                            .padding(.bottom, 2)
                        
                        Text("Date: \(expense.date, formatter: dateFormatter)")
                            .font(.subheadline)
                            .padding(.bottom, 2)
                        
                        Text("Paid by: \(expense.payer.Name)")
                            .font(.subheadline)
                            .padding(.bottom, 5)
                        
                        Divider()
                        
                        Text("Participants")
                            .font(.headline)
                            .padding(.vertical, 5)
                        
                        ForEach(expense.paymentDetails ?? [], id: \.participantID) { detail in
                            if let participant = expense.participants.first(where: { $0.id == detail.participantID }) {
                                VStack(alignment: .leading) {
                                    Text(participant.Name)
                                        .font(.subheadline)
                                    Text("Amount: \(detail.amount, specifier: "%.2f")")
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 2)
                            } else {
                                Text("Participant details not available.")
                                    .foregroundColor(.red)
                                    .font(.footnote)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Expense Detail")
            } else {
                VStack {
                    Text("Expense details not available.")
                        .foregroundColor(.red)
                        .font(.headline)
                    Spacer()
                }
                .padding()
                .navigationTitle("Expense Detail")
            }
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

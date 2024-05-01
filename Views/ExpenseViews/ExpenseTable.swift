//
//  ExpenseTable.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/26.
//
import SwiftUI

struct ExpenseTable: View {
    @EnvironmentObject var dataStore: DataStore
    @State private var showingAddExpenseView = false
    @State private var showingOCRView = false

    var body: some View {
        NavigationView {
            List {
                ForEach(dataStore.expenses) { expense in
                    ExpenseRow(expense: expense)
                }
                .onDelete(perform: deleteExpense)
            }
            .refreshable {
                refreshExpenses()
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshExpenses) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddExpenseView = true }) {
                        Label("Add Expense", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingOCRView = true }) {
                        Image(systemName: "camera")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpenseView) {
                AddExpense().environmentObject(dataStore)
            }
            .sheet(isPresented: $showingOCRView) {
                OCRView().environmentObject(dataStore)
            }

        }
    }

    private func refreshExpenses() {
        dataStore.fetchExpenses { fetchedExpenses in
            DispatchQueue.main.async {
                dataStore.expenses = fetchedExpenses
            }
        }
    }

    private func deleteExpense(at offsets: IndexSet) {
        offsets.forEach { index in
            let expenseID = dataStore.expenses[index].id
            dataStore.deleteExpense(expenseID: expenseID) { success, error in
                if success {
                    print("Expense successfully deleted")
                    DispatchQueue.main.async {
                        dataStore.expenses.remove(atOffsets: offsets)
                    }
                } else if let error = error {
                    print("Failed to delete expense: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct ExpenseRow: View {
    var expense: Expense

    var body: some View {
        HStack {
            Image(systemName: "creditcard.fill")
                .foregroundColor(.green)
                .frame(width: 32, height: 32)
            VStack(alignment: .leading) {
                Text(expense.description)
                    .fontWeight(.bold)
                Text("Amount: \(expense.totalAmount, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}


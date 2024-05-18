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
            VStack {
                if dataStore.expenses.isEmpty {
                    VStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("No Expenses")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(dataStore.expenses) { expense in
                            ExpenseRow(expense: expense)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                                .padding(.horizontal)
                        }
                        .onDelete(perform: deleteExpense)
                    }
                    .refreshable {
                        refreshExpenses()
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: refreshExpenses) {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button(action: { showingAddExpenseView = true }) {
                            Image(systemName: "plus")
                        }
                        Button(action: { showingOCRView = true }) {
                            Image(systemName: "camera")
                        }
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
    @EnvironmentObject var dataStore: DataStore

    var body: some View {
        NavigationLink(destination: ExpenseDetailView(expenseId: expense.id).environmentObject(dataStore)) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.green)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading) {
                    Text(expense.description)
                        .font(.headline)
                    Text("Amount: \(expense.totalAmount, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

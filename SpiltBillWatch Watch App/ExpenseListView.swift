//
//  ExpenseListView.swift
//  SpiltBillWatch Watch App
//
//  Created by Jason Ze on 2024/5/24.
//
import SwiftUI

struct ExpenseListView: View {
    @EnvironmentObject var dataStore: WatchDataStore

    var body: some View {
        List(dataStore.expenses) { expense in
            NavigationLink(destination: ExpenseDetailView(expense: expense)) {
                Text(expense.description)
            }
        }
        .navigationTitle("Expenses")
    }
}

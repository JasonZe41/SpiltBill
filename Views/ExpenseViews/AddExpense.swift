// AddExpense.swift
import SwiftUI

struct AddExpense: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var description: String = ""
    @State private var totalAmount: String = ""
    @State private var payer: Participant? = nil
    @State private var participants: [Participant] = []
    @State private var splitType: SplitType = .equally
    @State private var paymentDetails: [String] = []

    @State private var showingParticipantSearch = false
    @State private var showingPayerSearch = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Description", text: $description)
                    TextField("Total Amount", text: $totalAmount)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Select Payer")) {
                    if let payer = payer {
                        Text(payer.Name)
                    } else {
                        Button("Select Payer") {
                            showingPayerSearch = true
                        }
                    }
                }

                Section(header: Text("Split Type")) {
                    Picker("Split Type", selection: $splitType) {
                        ForEach(SplitType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Participants")) {
                    ForEach(participants.indices, id: \.self) { index in
                        HStack {
                            Text(participants[index].Name)
                            if splitType != .equally {
                                TextField("Amount", text: Binding<String>(get: {
                                    self.paymentDetails.indices.contains(index) ? self.paymentDetails[index] : ""
                                }, set: { newValue in
                                    if self.paymentDetails.indices.contains(index) {
                                        self.paymentDetails[index] = newValue
                                    }
                                }))
                                .keyboardType(.decimalPad)
                            }
                        }
                    }
                    Button("Add Participant") {
                        showingParticipantSearch = true
                    }
                }

                Section {
                    Button("Add Expense") {
                        addNewExpense()
                    }
                    .disabled(description.isEmpty || totalAmount.isEmpty || payer == nil || participants.isEmpty)
                }
            }
            .navigationBarTitle("Add Expense", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingParticipantSearch) {
                
                if let currentUser = dataStore.currentUser {
                                                ParticipantSearchView(selectedParticipants: $participants, allParticipants: $dataStore.friends, currentUser: currentUser)
                                            } else {
                                                // Optionally handle the case where the current user is not yet loaded
                                                Text("Loading user data...")
                                            }
            }
            .sheet(isPresented: $showingPayerSearch) {
                if let currentUser = dataStore.currentUser {  // Ensure currentUser is loaded before showing the view
                    ParticipantSearchView(
                        selectedParticipants: Binding(get: {
                            [payer].compactMap { $0 }  // Return an array with the current payer if not nil
                        }, set: { newValue in
                            payer = newValue.first  // Set the first selected participant as the payer
                            if let newPayer = newValue.first, !participants.contains(where: { $0.id == newPayer.id }) {
                                participants.append(newPayer)  // Add payer to participants if not already included
                            }
                        }),
                        allParticipants: $dataStore.friends,
                        currentUser: currentUser
                    )
                } else {
                    // Optionally handle the case where the current user is not yet loaded
                    Text("Loading user data...")
                }
            }

            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Expense Creation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func addNewExpense() {
        guard let totalAmountDouble = Double(totalAmount),
              let payer = payer else {
            alertMessage = "Invalid input. Please enter a valid number and select a payer."
            showingAlert = true
            return
        }

        // Prepare payment details based on the split type
        var details: [PaymentDetail] = []
        preparePaymentDetails(totalAmount: totalAmountDouble, details: &details)

        // Call addExpense on dataStore
        dataStore.addExpense(description: description, totalAmount: totalAmountDouble, participants: participants, payer: payer, splitType: splitType, paymentDetails: details) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    alertMessage = "Expense added successfully."
                case .failure(let error):
                    alertMessage = "An error occurred: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }

    private func preparePaymentDetails(totalAmount: Double, details: inout [PaymentDetail]) {
        switch splitType {
        case .equally:
            let splitAmount = totalAmount / Double(participants.count)
            details = participants.map { PaymentDetail(participantID: $0.id, amount: splitAmount) }
        case .percentage:
            details = paymentDetails.enumerated().compactMap { index, text in
                guard let percentage = Double(text), index < participants.count else { return nil }
                return PaymentDetail(participantID: participants[index].id, amount: (percentage / 100) * totalAmount)
            }
        case .byAmount:
            details = paymentDetails.enumerated().compactMap { index, text in
                guard let amount = Double(text), index < participants.count else { return nil }
                return PaymentDetail(participantID: participants[index].id, amount: amount)
            }
        }
    }
}


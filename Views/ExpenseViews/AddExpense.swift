//
//  AddExpense.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/30.
//

import SwiftUI

/// A SwiftUI view for adding a new expense.
struct AddExpense: View {
    @EnvironmentObject var dataStore: DataStore
    @Environment(\.dismiss) var dismiss

    @State private var description: String = ""
    @State private var totalAmount: String = ""
    @State private var payer: Participant? = nil
    @State private var participants: [Participant] = []
    @State private var splitType: SplitType = .equally
    @State private var paymentDetails: [String] = []
    @State private var receiptImage: UIImage?

    @State private var showingParticipantSearch = false
    @State private var showingPayerSearch = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    /// Initializes the AddExpense view with optional initial values.
    /// - Parameters:
    ///   - description: The initial description for the expense.
    ///   - totalAmount: The initial total amount for the expense.
    ///   - receiptImage: The initial receipt image for the expense.
    init(description: String = "", totalAmount: String = "", receiptImage: UIImage? = nil) {
        _description = State(initialValue: description)
        _totalAmount = State(initialValue: totalAmount)
        _receiptImage = State(initialValue: receiptImage)
    }

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
                        HStack {
                            Text(payer.Name)
                            Spacer()
                            Button("Change") {
                                showingPayerSearch = true
                            }
                        }
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
                                    } else {
                                        self.paymentDetails.append(newValue)
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

                Section {
                    if let payer = payer {
                        Button("Pay with Venmo") {
                            openVenmo()
                        }
                        .disabled(totalAmount.isEmpty || payer.PhoneNumber.isEmpty)
                    }
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
                    Text("Loading user data...")
                }
            }
            .sheet(isPresented: $showingPayerSearch) {
                if let currentUser = dataStore.currentUser {
                    ParticipantSearchView(
                        selectedParticipants: Binding(get: {
                            [payer].compactMap { $0 }
                        }, set: { newValue in
                            payer = newValue.first
                            if let newPayer = newValue.first, !participants.contains(where: { $0.id == newPayer.id }) {
                                participants.append(newPayer)
                            }
                        }),
                        allParticipants: $dataStore.friends,
                        currentUser: currentUser
                    )
                } else {
                    Text("Loading user data...")
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Expense Creation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    /// Adds a new expense by validating inputs and uploading image if provided.
    private func addNewExpense() {
        guard let totalAmountDouble = Double(totalAmount),
              let payer = payer,
              let details = preparePaymentDetails(totalAmount: totalAmountDouble) else {
            alertMessage = "Invalid input or error in calculating the payment details."
            showingAlert = true
            return
        }

        if let receiptImage = receiptImage {
            dataStore.uploadImage(receiptImage) { result in
                switch result {
                case .success(let url):
                    self.addExpenseToDataStore(imageURL: url, details: details, totalAmountDouble: totalAmountDouble, payer: payer)
                case .failure(let error):
                    self.alertMessage = "Image upload failed: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        } else {
            self.addExpenseToDataStore(imageURL: nil, details: details, totalAmountDouble: totalAmountDouble, payer: payer)
        }
    }

    /// Adds the expense data to the data store.
    /// - Parameters:
    ///   - imageURL: The URL of the uploaded receipt image.
    ///   - details: The payment details for the expense.
    ///   - totalAmountDouble: The total amount of the expense.
    ///   - payer: The payer of the expense.
    private func addExpenseToDataStore(imageURL: URL?, details: [PaymentDetail], totalAmountDouble: Double, payer: Participant) {
        dataStore.addExpense(description: description, totalAmount: totalAmountDouble, participants: participants, payer: payer, splitType: splitType, paymentDetails: details, imageURL: imageURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    self.alertMessage = "Expense added successfully."
                    self.showingAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.dismiss()
                    }
                case .failure(let error):
                    self.alertMessage = "An error occurred: \(error.localizedDescription)"
                    self.showingAlert = true
                }
            }
        }
    }

    /// Opens the Venmo app to pay the expense.
    private func openVenmo() {
        let venmoURL = "venmo://paycharge?txn=pay&recipients=\(payer?.PhoneNumber ?? "")&amount=\(totalAmount)&note=Splitting bill for \(description)"
        guard let url = URL(string: venmoURL) else { return }
        UIApplication.shared.open(url)
    }

    /// Prepares the payment details based on the selected split type.
    /// - Parameter totalAmount: The total amount of the expense.
    /// - Returns: An array of PaymentDetail objects if successful, otherwise nil.
    private func preparePaymentDetails(totalAmount: Double) -> [PaymentDetail]? {
        var details = [PaymentDetail]()

        switch splitType {
        case .equally:
            let splitAmount = (totalAmount / Double(participants.count))
            let totalRoundedAmount = splitAmount * Double(participants.count)
            let discrepancy = totalAmount - totalRoundedAmount

            details = participants.indices.map { index in
                let finalAmount = (index == participants.count - 1) ? splitAmount + discrepancy : splitAmount
                return PaymentDetail(participantID: participants[index].id, amount: finalAmount)
            }
        case .percentage:
            let totalPercentage = paymentDetails.compactMap { Double($0) }.reduce(0, +)
            if totalPercentage != 100 {
                alertMessage = "Total percentage does not add up to 100%."
                showingAlert = true
                return nil
            }
            details = paymentDetails.enumerated().compactMap { index, text in
                guard let percentage = Double(text), index < participants.count else { return nil }
                return PaymentDetail(participantID: participants[index].id, amount: (percentage / 100) * totalAmount)
            }
        case .byAmount:
            let paymentAmounts = paymentDetails.compactMap(Double.init)
            if paymentAmounts.count != participants.count {
                alertMessage = "Please enter a valid amount for each participant."
                showingAlert = true
                return nil
            }

            let totalSpecificAmounts = paymentAmounts.reduce(0, +)
            if totalSpecificAmounts != totalAmount {
                alertMessage = "The sum of amounts (\(totalSpecificAmounts)) does not equal the total amount (\(totalAmount))."
                showingAlert = true
                return nil
            }
            details = zip(participants, paymentAmounts).map { PaymentDetail(participantID: $0.id, amount: $1) }
        }
        return details
    }
}

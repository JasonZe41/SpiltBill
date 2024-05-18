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
    @State private var receiptImage: UIImage?


    @State private var showingParticipantSearch = false
    @State private var showingPayerSearch = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    
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
                                                            // Append new value if index does not exist
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
                
                // Payment Options Section
                              if !description.isEmpty && !totalAmount.isEmpty && payer != nil && !participants.isEmpty {
                                  Section(header: Text("Send Payment Request")) {
//                                      Button("Pay with PayPal") {
//                                          openPayPal()
//                                      }
                                      Button("Pay with Venmo") {
                                          openVenmo()
                                      }
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
              let payer = payer,
              let details = preparePaymentDetails(totalAmount: totalAmountDouble) else {
            alertMessage = "Invalid input or error in calculating the payment details."
            showingAlert = true
            return
        }

        
        let imageData = receiptImage?.jpegData(compressionQuality: 0.8)

        // Call addExpense on dataStore
        dataStore.addExpense(description: description, totalAmount: totalAmountDouble, participants: participants, payer: payer, splitType: splitType, paymentDetails: details, imageData: imageData) { result in
            DispatchQueue.main.async {
                switch result {
                case .success():
                    alertMessage = "Expense added successfully."
                    dismiss() // Optionally dismiss the view on success
                case .failure(let error):
                    alertMessage = "An error occurred: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }



//    private func openPayPal() {
//        guard let url = URL(string: "https://www.paypal.com/myaccount/transfer/send") else { return }
//        UIApplication.shared.open(url)
//    }

    private func openVenmo() {
        let venmoURL = "venmo://paycharge?txn=pay&recipients=\(payer?.PhoneNumber ?? "")&amount=\(totalAmount)&note=Splitting bill for \(description)"
        guard let url = URL(string: venmoURL) else { return }
        UIApplication.shared.open(url)
    }

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
            print("Original paymentDetails: \(paymentDetails)")  // Check what's in the array
            let totalPercentage = paymentDetails.compactMap { Double($0) }.reduce(0, +)
            print("Converted percentages: \(paymentDetails.compactMap(Double.init))")  // See the converted values
            print("Total percentage: \(totalPercentage)")
            
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
                let paymentAmounts = paymentDetails.compactMap(Double.init) // Convert to Double
                    print("paymentAmounts\(paymentAmounts)")
                print(type(of: paymentAmounts))
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


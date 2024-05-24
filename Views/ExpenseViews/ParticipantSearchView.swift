//
//  ParticipantSearchView.swift
//  SpiltBill
//
//  Created by Jason Ze on 2024/4/30.
//

import SwiftUI

/// A SwiftUI view that allows the user to search and select participants for an expense.
struct ParticipantSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedParticipants: [Participant]
    @Binding var allParticipants: [Participant]
    @State private var searchText = ""
    let currentUser: Participant

    /// Filters participants based on the search text.
    var filteredParticipants: [Participant] {
        if searchText.isEmpty {
            return allParticipants
        } else {
            return allParticipants.filter { $0.Name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                    .padding()

                List {
                    Section(header: Text("Current User")) {
                        ParticipantRow(participant: currentUser, isSelected: isSelected(currentUser))
                            .onTapGesture {
                                toggleParticipant(currentUser)
                            }
                    }

                    Section(header: Text("Participants")) {
                        ForEach(filteredParticipants, id: \.id) { participant in
                            ParticipantRow(participant: participant, isSelected: isSelected(participant))
                                .onTapGesture {
                                    toggleParticipant(participant)
                                }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitle("Select Participants", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }

    /// Checks if a participant is already selected.
    /// - Parameter participant: The participant to check.
    /// - Returns: A boolean indicating whether the participant is selected.
    private func isSelected(_ participant: Participant) -> Bool {
        selectedParticipants.contains { $0.id == participant.id }
    }

    /// Toggles the selection of a participant.
    /// - Parameter participant: The participant to toggle.
    private func toggleParticipant(_ participant: Participant) {
        if let index = selectedParticipants.firstIndex(where: { $0.id == participant.id }) {
            selectedParticipants.remove(at: index)
        } else {
            selectedParticipants.append(participant)
        }
    }
}

/// A SwiftUI view representing a row for a participant.
struct ParticipantRow: View {
    var participant: Participant
    var isSelected: Bool

    var body: some View {
        HStack {
            Text(participant.Name)
                .foregroundColor(isSelected ? .white : .primary)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(isSelected ? Color.blue : Color.clear)
        .cornerRadius(8)
    }
}

/// A SwiftUI view representing a search bar.
struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.primary)
                .autocapitalization(.none)
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

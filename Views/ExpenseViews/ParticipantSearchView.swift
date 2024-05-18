//  ParticipantSearchView.swift
//  ParticipantSearchView.swift
import SwiftUI

struct ParticipantSearchView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedParticipants: [Participant]
    @Binding var allParticipants: [Participant]
    @State private var searchText = ""
    let currentUser: Participant

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

    private func isSelected(_ participant: Participant) -> Bool {
        selectedParticipants.contains { $0.id == participant.id }
    }

    private func toggleParticipant(_ participant: Participant) {
        if let index = selectedParticipants.firstIndex(where: { $0.id == participant.id }) {
            selectedParticipants.remove(at: index)
        } else {
            selectedParticipants.append(participant)
        }
    }
}

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

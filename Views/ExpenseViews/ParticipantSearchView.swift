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
            List {
                
//                TextField("Search", text: $searchText)
//                                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                                    .padding()

                ParticipantRow(participant: currentUser, isSelected: isSelected(currentUser))
                                   .onTapGesture {
                                       toggleParticipant(currentUser)
                                   }

                ForEach(filteredParticipants, id: \.id) { participant in
                    ParticipantRow(participant: participant, isSelected: isSelected(participant))
                        .onTapGesture {
                            toggleParticipant(participant)
                        }
                }
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

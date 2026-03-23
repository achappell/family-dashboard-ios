import SwiftUI

struct AddChoreView: View {
    @Environment(SupabaseManager.self) private var supabaseManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedParticipantId: String?
    @State private var dueDate = Date()
    @State private var isRecurring = false
    @State private var recurrencePattern = "daily"
    @State private var selectedDays: Set<Int> = []
    
    let recurrenceOptions = ["daily", "weekly", "monthly"]
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Chore Details") {
                    TextField("Title (e.g. Empty Dishwasher)", text: $title)
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("Assignment") {
                    Picker("Assign to", selection: $selectedParticipantId) {
                        Text("Unassigned").tag(nil as String?)
                        ForEach(supabaseManager.participants) { participant in
                            Text(participant.name).tag(participant.id as String?)
                        }
                    }
                }
                
                Section("Schedule") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    
                    Toggle("Recurring Chore", isOn: $isRecurring)
                    
                    if isRecurring {
                        Picker("Repeat", selection: $recurrencePattern) {
                            ForEach(recurrenceOptions, id: \.self) { option in
                                Text(option.capitalized).tag(option)
                            }
                        }
                        
                        if recurrencePattern == "weekly" {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Repeat on")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    ForEach(0..<7) { index in
                                        Button {
                                            if selectedDays.contains(index) {
                                                selectedDays.remove(index)
                                            } else {
                                                selectedDays.insert(index)
                                            }
                                        } label: {
                                            Text(daysOfWeek[index])
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .frame(width: 35, height: 35)
                                                .background(selectedDays.contains(index) ? Color.accentColor : Color(uiColor: .systemGray6))
                                                .foregroundColor(selectedDays.contains(index) ? .white : .primary)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("New Chore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveChore()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func saveChore() {
        Task {
            let newChore = Chore(
                id: UUID().uuidString.lowercased(),
                title: title,
                description: description.isEmpty ? nil : description,
                participantId: selectedParticipantId,
                isCompleted: false,
                dueDate: dueDate,
                recurrence: isRecurring ? recurrencePattern : "none",
                recurringDays: recurrencePattern == "weekly" ? Array(selectedDays).sorted() : [],
                lastCompletedAt: nil
            )
            await supabaseManager.addChore(newChore)
            dismiss()
        }
    }
}

#Preview {
    AddChoreView()
        .environment(SupabaseManager.shared)
}

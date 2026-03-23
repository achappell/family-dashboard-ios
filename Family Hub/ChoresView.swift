import SwiftUI

struct ChoresView: View {
    @Environment(SupabaseManager.self) private var supabaseManager
    @State private var showingAddChore = false
    @State private var filterMode = 0 // 0 = Today, 1 = All
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Filter", selection: $filterMode) {
                    Text("Today").tag(0)
                    Text("All").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(uiColor: .systemGroupedBackground))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        if supabaseManager.participants.isEmpty {
                            Text("No participants found.")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(supabaseManager.participants) { participant in
                                participantChoreCard(for: participant)
                                    .frame(width: 280)
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Chores")
            .toolbar {
                Button {
                    showingAddChore = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
            .fullScreenCover(isPresented: $showingAddChore) {
                AddChoreView()
            }
            .task {
                await supabaseManager.fetchChores()
            }
        }
    }
    
    private func participantChoreCard(for participant: Participant) -> some View {
        let today = Calendar.current.startOfDay(for: Date())
        let chores = supabaseManager.chores.filter { chore in
            if filterMode == 0 { // Today + Overdue uncompleted
                guard let dueDate = chore.dueDate else { return false }
                let isDueToday = Calendar.current.isDate(dueDate, inSameDayAs: today)
                let isOverdueUncompleted = dueDate < today && !chore.isCompleted
                return (isDueToday || isOverdueUncompleted) && chore.participantId == participant.id
            } else { // All chores
                return chore.participantId == participant.id
            }
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(participant.name)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: participant.color).opacity(0.1))
                .foregroundColor(Color(hex: participant.color))
                .cornerRadius(8)
            
            if chores.isEmpty {
                Text(filterMode == 0 ? "No chores due today! 🎉" : "All caught up! 🎉")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(chores) { chore in
                    let isDone = if chore.recurrence == "none" {
                        chore.isCompleted
                    } else {
                        if let last = chore.lastCompletedAt {
                            Calendar.current.isDate(last, inSameDayAs: Date())
                        } else {
                            false
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Button {
                                Task {
                                    await supabaseManager.toggleChore(chore)
                                }
                            } label: {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isDone ? .green : .secondary)
                                    .font(.title2)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(chore.title)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .strikethrough(isDone)
                                    .foregroundColor(isDone ? .secondary : .primary)
                                
                                if let description = chore.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            if let dueDate = chore.dueDate {
                                Label {
                                    Text(dueDate.formatted(.dateTime.month().day()))
                                } icon: {
                                    Image(systemName: "calendar")
                                }
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(isOverdue(dueDate) && !chore.isCompleted ? Color.red.opacity(0.1) : Color.secondary.opacity(0.1))
                                .foregroundColor(isOverdue(dueDate) && !chore.isCompleted ? .red : .secondary)
                                .cornerRadius(6)
                            }
                            
                            if chore.recurrence != "none" {
                                Label {
                                    if chore.recurrence == "weekly" && !chore.recurringDays.isEmpty {
                                        Text(chore.recurringDays.map { daysOfWeekShort[$0] }.joined(separator: ","))
                                    } else {
                                        Text(chore.recurrence.capitalized)
                                    }
                                } icon: {
                                    Image(systemName: "arrow.2.squarepath")
                                }
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .foregroundColor(.secondary)
                                .cornerRadius(6)
                            }
                        }
                        .padding(.leading, 34)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
        }
    }
    
    private let daysOfWeekShort = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Calendar.current.startOfDay(for: Date())
    }
}

#Preview {
    let manager = SupabaseManager.shared
    let _ = {
        manager.children = [
            Child(id: "1", name: "Sarah", color: "#FF3B30", familyId: nil),
            Child(id: "2", name: "Leo", color: "#007AFF", familyId: nil)
        ]
        manager.chores = [
            Chore(id: "a", title: "Empty Dishwasher", description: "Kitchen needs to be clean before dinner", participantId: "1", isCompleted: false, dueDate: Date(), recurrence: "daily", recurringDays: [], lastCompletedAt: nil),
            Chore(id: "b", title: "Walk Dog", description: "Take Buster for a 15 min walk", participantId: "2", isCompleted: true, dueDate: Date(), recurrence: "weekly", recurringDays: [1, 3, 5], lastCompletedAt: Date()),
            Chore(id: "c", title: "Clean Room", description: nil, participantId: "1", isCompleted: false, dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), recurrence: "none", recurringDays: [], lastCompletedAt: nil)
        ]
    }()
    
    ChoresView()
        .environment(manager)
}

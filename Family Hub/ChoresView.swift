import SwiftUI

struct ChoresView: View {
    @Environment(SupabaseManager.self) private var supabaseManager
    @State private var showingAddChore = false
    @State private var newChoreTitle = ""
    @State private var selectedChildId: String?
    
    var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    if supabaseManager.children.isEmpty {
                        Text("Add children in Settings to see the chore chart.")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(supabaseManager.children) { child in
                            childChoreCard(for: child)
                                .frame(width: 280)
                        }
                    }
                }
                .padding()
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
            .sheet(isPresented: $showingAddChore) {
                NavigationStack {
                    Form {
                        TextField("What needs to be done?", text: $newChoreTitle)
                        Picker("Assign to", selection: $selectedChildId) {
                            Text("Unassigned").tag(nil as String?)
                            ForEach(supabaseManager.children) { child in
                                Text(child.name).tag(child.id as String?)
                            }
                        }
                    }
                    .navigationTitle("New Chore")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddChore = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                Task {
                                    let chore = Chore(
                                        id: UUID().uuidString.lowercased(),
                                        title: newChoreTitle,
                                        description: nil,
                                        childId: selectedChildId,
                                        isCompleted: false,
                                        dueDate: nil
                                    )
                                    await supabaseManager.addChore(chore)
                                    newChoreTitle = ""
                                    showingAddChore = false
                                }
                            }
                            .disabled(newChoreTitle.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .task {
                await supabaseManager.fetchChores()
            }
        }
    }
    
    private func childChoreCard(for child: Child) -> some View {
        let childChores = supabaseManager.chores.filter { $0.childId == child.id }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text(child.name)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(hex: child.color).opacity(0.1))
                .foregroundColor(Color(hex: child.color))
                .cornerRadius(8)
            
            if childChores.isEmpty {
                Text("All caught up! 🎉")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(childChores) { chore in
                    HStack {
                        Button {
                            Task {
                                await supabaseManager.toggleChore(chore)
                            }
                        } label: {
                            Image(systemName: chore.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(chore.isCompleted ? .green : .secondary)
                                .font(.title3)
                        }
                        
                        Text(chore.title)
                            .font(.subheadline)
                            .strikethrough(chore.isCompleted)
                            .foregroundColor(chore.isCompleted ? .secondary : .primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: child.color).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ChoresView()
        .environment(SupabaseManager.shared)
}

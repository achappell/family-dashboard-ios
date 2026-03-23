//
//  ContentView.swift
//  Family Hub
//
//  Created by Amanda Chappell on 3/22/26.
//

import SwiftUI
internal import Auth

struct ContentView: View {
    @State private var supabaseManager = SupabaseManager.shared
    
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            ChoresView()
                .tabItem {
                    Label("Chores", systemImage: "checklist")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environment(supabaseManager)
        .task {
            await supabaseManager.fetchChildren()
        }
    }
}

struct SettingsView: View {
    @Environment(SupabaseManager.self) private var supabaseManager
    @State private var showingAddChild = false
    @State private var newChildName = ""
    @State private var newChildColor = Color.blue
    
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let session = supabaseManager.session {
                        Text(session.user.email ?? "No email")
                            .font(.subheadline)
                        Button("Sign Out", role: .destructive) {
                            Task {
                                await supabaseManager.signOut()
                            }
                        }
                    } else {
                        Button("Sign in with Google") {
                            Task {
                                await supabaseManager.signInWithGoogle()
                            }
                        }
                    }
                }
                
                Section("Calendar") {
                    Picker("Selected Calendar", selection: Bindable(supabaseManager).selectedCalendarId) {
                        if supabaseManager.calendars.isEmpty {
                            Text("Primary").tag("primary")
                        }
                        ForEach(supabaseManager.calendars) { cal in
                            Text(cal.summary).tag(cal.id)
                        }
                    }
                }
                
                Section {
                    ForEach(supabaseManager.children) { child in
                        NavigationLink {
                            EditChildView(child: child)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(hex: child.color))
                                    .frame(width: 12, height: 12)
                                Text(child.name)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let child = supabaseManager.children[index]
                            Task {
                                await supabaseManager.deleteChild(child)
                            }
                        }
                    }
                    
                    Button {
                        showingAddChild = true
                    } label: {
                        Label("Add Child", systemImage: "plus")
                    }
                } header: {
                    Text("Children")
                } footer: {
                    Text("Events containing a child's name will be highlighted in their color.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddChild) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newChildName)
                        ColorPicker("Color", selection: $newChildColor)
                    }
                    .navigationTitle("New Child")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddChild = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                Task {
                                    await supabaseManager.addChild(
                                        name: newChildName,
                                        color: newChildColor.toHex() ?? "#0000FF"
                                    )
                                    newChildName = ""
                                    showingAddChild = false
                                }
                            }
                            .disabled(newChildName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}

struct EditChildView: View {
    let child: Child
    @Environment(SupabaseManager.self) private var supabaseManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var color: Color
    
    init(child: Child) {
        self.child = child
        _name = State(initialValue: child.name)
        _color = State(initialValue: Color(hex: child.color))
    }
    
    var body: some View {
        Form {
            TextField("Name", text: $name)
            ColorPicker("Color", selection: $color)
            
            Section {
                Button("Save Changes") {
                    Task {
                        let updatedChild = Child(
                            id: child.id,
                            name: name,
                            color: color.toHex() ?? "#0000FF",
                            familyId: child.familyId
                        )
                        await supabaseManager.updateChild(updatedChild)
                        dismiss()
                    }
                }
                .disabled(name.isEmpty)
                
                Button("Delete Child", role: .destructive) {
                    Task {
                        await supabaseManager.deleteChild(child)
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Edit \(child.name)")
    }
}

extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

#Preview("Main Content") {
    ContentView()
}

#Preview("Settings") {
    SettingsView()
        .environment(SupabaseManager.shared)
}

#Preview("Edit Child") {
    EditChildView(child: Child(id: "1", name: "Sarah", color: "#FF0000", familyId: nil))
        .environment(SupabaseManager.shared)
}

import Foundation
import Supabase

@Observable
@MainActor
class SupabaseManager {
    static let shared = SupabaseManager()
    
    var session: Session?
    var children: [Child] = []
    var participants: [Participant] = []
    var chores: [Chore] = []
    var calendars: [CalendarInfo] = []
    var selectedCalendarId: String = UserDefaults.standard.string(forKey: "selectedCalendarId") ?? "primary" {
        didSet {
            UserDefaults.standard.set(selectedCalendarId, forKey: "selectedCalendarId")
        }
    }
    var isLoading: Bool = false
    var error: Error?
    
    private init() {
        listenToAuthChanges()
    }
    
    func listenToAuthChanges() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                print("Auth event: \(event)")
                await MainActor.run {
                    self.session = session
                }
                
                if session != nil {
                    await fetchParticipants()
                    await fetchChores()
                    await fetchCalendars()
                    subscribeToChores() // Start real-time subscription
                }
            }
        }
    }

    func fetchParticipants() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 1. Fetch Children
            let fetchedChildren: [Child] = try await supabase
                .from("children")
                .select()
                .execute()
                .value
            self.children = fetchedChildren
            
            // 2. Fetch Family Members (Users)
            // We'll need the familyId first. Currently we fetch all members, ideally filtered by family.
            let members: [FamilyMemberResponse] = try await supabase
                .from("family_members")
                .select("user_id, profiles(first_name)")
                .execute()
                .value
            
            // Map to Participants
            let childParticipants = fetchedChildren.map { Participant(id: $0.id, name: $0.name, color: $0.color, isUser: false) }
            
            let userParticipants = members.map { m in
                let uid = m.userId
                let firstName = m.profiles?.firstName
                let displayName = firstName ?? "User " + uid.prefix(4)
                return Participant(id: uid, name: displayName, color: "#8e8e93", isUser: true)
            }
            
            self.participants = childParticipants + userParticipants
        } catch {
            print("Error fetching participants: \(error)")
        }
    }

    private var choresChannel: RealtimeChannelV2?

    func subscribeToChores() {
        if let existing = choresChannel {
            Task { await supabase.removeChannel(existing) }
        }

        let channel = supabase.channel("public:chores")
        let changes = channel.postgresChange(AnyAction.self, schema: "public", table: "chores")
        
        Task {
            for await action in changes {
                await MainActor.run {
                    do {
                        switch action {
                        case .insert(let insertAction):
                            let newChore = try insertAction.decodeRecord(as: Chore.self, decoder: JSONDecoder())
                            print("Real-time INSERT: \(newChore.title)")
                            self.chores.append(newChore)
                            
                        case .update(let updateAction):
                            let updatedChore = try updateAction.decodeRecord(as: Chore.self, decoder: JSONDecoder())
                            print("Real-time UPDATE: \(updatedChore.title) (Completed: \(updatedChore.isCompleted))")
                            if let index = self.chores.firstIndex(where: { $0.id == updatedChore.id }) {
                                self.chores[index] = updatedChore
                            }
                            
                        case .delete(let deleteAction):
                            if case .string(let id) = deleteAction.oldRecord["id"] {
                                print("Real-time DELETE: \(id)")
                                self.chores.removeAll(where: { $0.id == id })
                            }
                        }
                    } catch {
                        print("Error decoding real-time chore: \(error)")
                    }
                }
            }
        }
        
        Task {
            do {
                try await channel.subscribeWithError()
            } catch {
                print("Error subscribing to realtime channel: \(error)")
            }
        }
        self.choresChannel = channel
    }
    
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            await MainActor.run {
                self.session = session
            }
        } catch {
            print("No active session: \(error)")
        }
    }

    func fetchCalendars() async {
        guard let providerToken = session?.providerToken else { 
            print("fetchCalendars: No provider token found")
            return 
        }
        
        var request = URLRequest(url: URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")!)
        request.setValue("Bearer \(providerToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(GoogleCalendarListResponse.self, from: data)
            self.calendars = response.items.map { CalendarInfo(id: $0.id, summary: $0.summary ?? "Unnamed") }
        } catch {
            print("Error fetching calendars: \(error)")
        }
    }
    
    func signInWithGoogle() async {
        do {
            try await supabase.auth.signInWithOAuth(provider: .google, redirectTo: URL(string: "io.supabase.familyhub://login-callback"), queryParams: [
                                            (name: "access_type", value: "offline"),
                                            (name: "prompt", value: "consent"),
                                            (name:"scopes", value: "https://www.googleapis.com/auth/calendar.readonly")])
            
        } catch {
            self.error = error
        }
    }
    
    func fetchChildren() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let children: [Child] = try await supabase
                .from("children")
                .select()
                .execute()
                .value
            
            self.children = children
        } catch {
            self.error = error
            print("Error fetching children: \(error)")
        }
    }
    
    func fetchChores() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let chores: [Chore] = try await supabase
                .from("chores")
                .select()
                .execute()
                .value
            
            self.chores = chores
        } catch {
            self.error = error
            print("Error fetching chores: \(error)")
        }
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.session = nil
            self.children = []
            self.chores = []
            self.calendars = []
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    func addChild(name: String, color: String) async {
        do {
            let newChild = Child(id: UUID().uuidString.lowercased(), name: name, color: color, familyId: nil)
            
            try await supabase
                .from("children")
                .insert(newChild)
                .execute()
            
            await fetchChildren()
        } catch {
            self.error = error
            print("Error adding child: \(error)")
        }
    }
    
    func updateChild(_ child: Child) async {
        do {
            try await supabase
                .from("children")
                .update(child)
                .eq("id", value: child.id)
                .execute()
            
            await fetchChildren()
        } catch {
            self.error = error
            print("Error updating child: \(error)")
        }
    }
    
    func deleteChild(_ child: Child) async {
        do {
            try await supabase
                .from("children")
                .delete()
                .eq("id", value: child.id)
                .execute()
            
            await fetchChildren()
        } catch {
            self.error = error
            print("Error deleting child: \(error)")
        }
    }
    
    func toggleChore(_ chore: Chore) async {
        do {
            if chore.recurrence == "none" {
                // Regular chore: toggle isCompleted
                try await supabase
                    .from("chores")
                    .update(["is_completed": !chore.isCompleted])
                    .eq("id", value: chore.id)
                    .execute()
            } else {
                // Recurring chore: toggle last_completed_at for today
                let isCurrentlyDoneToday = if let last = chore.lastCompletedAt {
                    Calendar.current.isDate(last, inSameDayAs: Date())
                } else {
                    false
                }
                
                let newDate: Date? = isCurrentlyDoneToday ? nil : Date()
                
                try await supabase
                    .from("chores")
                    .update(["last_completed_at": newDate])
                    .eq("id", value: chore.id)
                    .execute()
            }
            
            await fetchChores()
        } catch {
            self.error = error
            print("Error toggling chore: \(error)")
        }
    }
    
    func addChore(_ chore: Chore) async {
        do {
            try await supabase
                .from("chores")
                .insert(chore)
                .execute()
            
            await fetchChores()
        } catch {
            self.error = error
            print("Error adding chore: \(error)")
        }
    }
    
    func fetchGoogleEvents(calendarId: String = "primary", startDate: Date) async -> [CalendarEvent] {
        guard let providerToken = session?.providerToken else {
            print("fetchGoogleEvents: No provider token found")
            return []
        }
        
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: startDate))!
        let endOfWeek = Calendar.current.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        let isoFormatter = ISO8601DateFormatter()
        let timeMin = isoFormatter.string(from: startOfWeek)
        let timeMax = isoFormatter.string(from: endOfWeek)
        
        var urlComponents = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(calendarId)/events")!
        urlComponents.queryItems = [
            URLQueryItem(name: "timeMin", value: timeMin),
            URLQueryItem(name: "timeMax", value: timeMax),
            URLQueryItem(name: "singleEvents", value: "true"),
            URLQueryItem(name: "orderBy", value: "startTime")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(providerToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            
            let response = try decoder.decode(GoogleCalendarResponse.self, from: data)
            
            let fullFormatter = ISO8601DateFormatter()
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "yyyy-MM-dd"
            dayFormatter.timeZone = TimeZone(secondsFromGMT: 0)

            return response.items.map { item in
                let isAllDay = item.start.dateTime == nil
                let startStr = item.start.dateTime ?? item.start.date ?? ""
                let endStr = item.end.dateTime ?? item.end.date ?? startStr
                
                let start = fullFormatter.date(from: startStr) ?? dayFormatter.date(from: startStr) ?? Date()
                let end = fullFormatter.date(from: endStr) ?? dayFormatter.date(from: endStr) ?? start
                
                return CalendarEvent(
                    id: item.id,
                    summary: item.summary ?? "No Title",
                    start: start,
                    end: end,
                    isAllDay: isAllDay
                )
            }
        } catch {
            print("Error fetching Google events: \(error)")
            return []
        }
    }
}

struct GoogleCalendarListResponse: Codable {
    let items: [GoogleCalendarListItem]
}

struct GoogleCalendarListItem: Codable {
    let id: String
    let summary: String?
}

struct GoogleCalendarResponse: Codable {
    let items: [GoogleCalendarEventItem]
}

struct GoogleCalendarEventItem: Codable {
    let id: String
    let summary: String?
    let start: GoogleCalendarTime
    let end: GoogleCalendarTime
}

struct GoogleCalendarTime: Codable {
    let dateTime: String?
    let date: String?
}

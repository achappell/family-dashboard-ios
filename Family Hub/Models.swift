import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String?
    let lastName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct Child: Codable, Identifiable {
    let id: String
    let name: String
    let color: String // Hex string
    let familyId: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case color
        case familyId = "family_id"
    }
}

struct Participant: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let color: String
    let isUser: Bool
}

struct CalendarInfo: Codable, Identifiable, Hashable {
    let id: String
    let summary: String
}

struct FamilyMemberResponse: Codable {
    let userId: String
    let profiles: ProfileResponse?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case profiles
    }
}

struct ProfileResponse: Codable {
    let firstName: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
    }
}

struct Family: Codable, Identifiable {
    let id: String
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}

struct CalendarEvent: Codable, Identifiable {
    let id: String
    let summary: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case summary
        case start
        case end
        case isAllDay = "is_all_day"
    }
}

struct Chore: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let participantId: String?
    let isCompleted: Bool
    let dueDate: Date?
    let recurrence: String // 'none', 'daily', 'weekly', etc.
    let recurringDays: [Int] // 0-6 for Sun-Sat
    let lastCompletedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case participantId = "participant_id"
        case isCompleted = "is_completed"
        case dueDate = "due_date"
        case recurrence
        case recurringDays = "recurring_days"
        case lastCompletedAt = "last_completed_at"
    }
}

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

struct CalendarInfo: Codable, Identifiable, Hashable {
    let id: String
    let summary: String
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
    let childId: String?
    let isCompleted: Bool
    let dueDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case childId = "child_id"
        case isCompleted = "is_completed"
        case dueDate = "due_date"
    }
}

import Foundation
import Observation

@Observable
class CalendarViewModel {
    var events: [CalendarEvent] = []
    var currentDate: Date = Date()
    var isLoading: Bool = false
    var selectedCalendarId: String = "primary"
    
    func nextDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        Task { await fetchEvents() }
    }
    
    func previousDay() {
        currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        Task { await fetchEvents() }
    }
    
    func fetchEvents() async {
        isLoading = true
        defer { isLoading = false }
        
        // We still fetch a week's worth of events from the API for better caching/navigation
        // but the UI will filter to show only one day.
        let fetchedEvents = await SupabaseManager.shared.fetchGoogleEvents(calendarId: selectedCalendarId, startDate: currentDate)
        self.events = fetchedEvents
    }
}

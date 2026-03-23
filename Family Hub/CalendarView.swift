import SwiftUI
import Supabase

struct CalendarView: View {
    @State private var viewModel = CalendarViewModel()
    @Environment(SupabaseManager.self) private var supabaseManager
    
    private let hourHeight: CGFloat = 60
    private let timeColumnWidth: CGFloat = 60
    
    var body: some View {
        VStack(spacing: 0) {
            header
            
            GeometryReader { geometry in
                ScrollView {
                    ZStack(alignment: .topLeading) {
                        timeGrid
                        
                        HStack(spacing: 0) {
                            Spacer().frame(width: timeColumnWidth)
                            
                            dayColumn(for: viewModel.currentDate, width: geometry.size.width - timeColumnWidth)
                        }
                        
                        currentTimeLine(width: geometry.size.width)
                    }
                }
            }
        }
        .task(id: supabaseManager.selectedCalendarId) {
            viewModel.selectedCalendarId = supabaseManager.selectedCalendarId
            await viewModel.fetchEvents()
        }
        .task(id: supabaseManager.session?.accessToken) {
            if supabaseManager.session != nil {
                await viewModel.fetchEvents()
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { viewModel.previousDay() }) {
                    Image(systemName: "chevron.left")
                        .padding()
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(viewModel.currentDate.formatted(.dateTime.weekday(.wide)))
                        .font(.caption)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.currentDate.formatted(.dateTime.month().day().year()))
                        .font(.headline)
                }
                
                Spacer()
                
                Button(action: { viewModel.nextDay() }) {
                    Image(systemName: "chevron.right")
                        .padding()
                }
            }
            .padding(.horizontal)
            
            Divider()
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    private var timeGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<24) { hour in
                HStack(spacing: 0) {
                    Text(formatHour(hour))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(width: timeColumnWidth, height: hourHeight, alignment: .topTrailing)
                        .padding(.trailing, 8)
                        .offset(y: -6)
                    
                    VStack {
                        Divider()
                        Spacer()
                    }
                }
                .frame(height: hourHeight)
            }
        }
    }
    
    private func dayColumn(for day: Date, width: CGFloat) -> some View {
        let events = viewModel.events.filter { Calendar.current.isDate($0.start, inSameDayAs: day) && !$0.isAllDay }
        
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: width)
            
            ForEach(events) { event in
                eventPill(for: event)
                    .frame(width: width - 20)
                    .offset(x: 10, y: offsetForDate(event.start))
            }
        }
    }
    
    private func eventPill(for event: CalendarEvent) -> some View {
        let color = colorForEvent(event)
        let height = heightForEvent(event)
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(event.summary)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(2)
            
            if height > 40 {
                Text(event.start.formatted(.dateTime.hour().minute()) + " - " + event.end.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .opacity(0.8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(height: height, alignment: .topLeading)
        .background(color.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            Rectangle()
                .fill(color)
                .frame(width: 4),
            alignment: .leading
        )
        .foregroundColor(color)
    }
    
    private func currentTimeLine(width: CGFloat) -> some View {
        let now = Date()
        guard Calendar.current.isDate(now, inSameDayAs: viewModel.currentDate) else { return AnyView(EmptyView()) }
        
        return AnyView(
            HStack(spacing: 0) {
                Spacer().frame(width: timeColumnWidth)
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: -4)
                Rectangle()
                    .fill(Color.red)
                    .frame(height: 2)
            }
            .offset(y: offsetForDate(now))
        )
    }
    
    // MARK: - Helpers
    
    private func formatHour(_ hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour == 12 { return "12 PM" }
        return hour < 12 ? "\(hour) AM" : "\(hour - 12) PM"
    }
    
    private func offsetForDate(_ date: Date) -> CGFloat {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = CGFloat(components.hour ?? 0)
        let minute = CGFloat(components.minute ?? 0)
        return (hour * hourHeight) + (minute / 60 * hourHeight)
    }
    
    private func heightForEvent(_ event: CalendarEvent) -> CGFloat {
        let duration = event.end.timeIntervalSince(event.start)
        let height = CGFloat(duration / 3600) * hourHeight
        return max(height, 35) // Minimum height
    }
    
    private func colorForEvent(_ event: CalendarEvent) -> Color {
        for child in supabaseManager.children {
            if event.summary.lowercased().contains(child.name.lowercased()) {
                return Color(hex: child.color)
            }
        }
        return .blue
    }
}

#Preview {
    CalendarView()
        .environment(SupabaseManager.shared)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

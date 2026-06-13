import Foundation

struct CalendarDay: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

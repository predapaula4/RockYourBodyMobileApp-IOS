import SwiftUI

struct HorizontalCalendarView: View {
    @Binding var selectedDate: Date
    let themeColor: Color
    let onDateSelected: (Date) -> Void
    
    private let pastDays: [Date] = {
        let today = Date()
        return (0...14).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }()
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 12) {
                    ForEach(pastDays, id: \.self) { date in
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        
                        VStack(spacing: 4) {
                            Text(dayOfWeek(from: date))
                                .font(.caption)
                                .foregroundColor(isSelected ? themeColor : .gray)
                            Text(dayOfMonth(from: date))
                                .font(.headline)
                                .foregroundColor(.white)
                                .opacity(isSelected ? 1.0 : 0.6)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(isSelected ? themeColor.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                        .id(date)
                        .onTapGesture {
                            withAnimation {
                                selectedDate = date
                                onDateSelected(date)
                            }
                        }
                    }
                }
                .padding()
                .onAppear {
                    // La deschidere, scrollăm automat la ziua de azi (ultima din dreapta)
                    if let lastDate = pastDays.last {
                        proxy.scrollTo(lastDate, anchor: .trailing)
                    }
                }
            }
        }
        .background(Color(hex: "#1E1E1E"))
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "EEE"; formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
    
    private func dayOfMonth(from date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

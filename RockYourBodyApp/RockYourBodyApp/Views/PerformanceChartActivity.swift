import SwiftUI
import HealthKit

enum PerformanceMetricType: String {
    case distance = "DISTANCE"
    case floors = "FLOORS"
    case speed = "SPEED"
    case elevation = "ELEVATION"
    case intensity = "INTENSITY"
    case cadence = "CADENCE"
}

struct PerformanceChartView: View {
    @Environment(\.dismiss) var dismiss
    let metricType: PerformanceMetricType
    
    // Stări
    @State private var selectedDate = Date()
    @State private var currentValue: Double = 0.0 // Aici va veni valoarea din HealthKitManager pentru ziua respectivă
    
    // Generăm ultimele 14 zile pentru calendar (ca în Android)
    private let pastDays: [Date] = {
        let today = Date()
        return (0...14).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }.reversed()
    }()
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea()
            
            VStack(spacing: 0) {
                // --- HEADER CUSTOM ---
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(config.color)
                    }
                    Spacer()
                    Text(headerTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .opacity(0) // Spacer invizibil pentru centrare
                }
                .padding()
                
                // --- CALENDAR ORIZONTAL ---
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(pastDays, id: \.self) { date in
                            DayCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate), themeColor: config.color)
                                .onTapGesture {
                                    withAnimation {
                                        selectedDate = date
                                        loadDataForDate(date)
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .background(Color(hex: "#1E1E1E"))
                
                // --- CONȚINUT PRINCIPAL ---
                ScrollView {
                    VStack(spacing: 32) {
                        
                        Text("Performance Data")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.top, 24)
                        
                        // --- PROGRESS CIRCULAR ---
                        ZStack {
                            Circle()
                                .stroke(config.color.opacity(0.2), lineWidth: 12)
                                .frame(width: 200, height: 200)
                            
                            Circle()
                                .trim(from: 0.0, to: min(CGFloat(currentValue / config.maxTarget), 1.0))
                                .stroke(config.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .frame(width: 200, height: 200)
                                .rotationEffect(Angle(degrees: -90))
                                .animation(.easeOut(duration: 1.0), value: currentValue)
                            
                            VStack(spacing: 8) {
                                Image(systemName: config.iconName)
                                    .font(.title)
                                    .foregroundColor(.white)
                                
                                Text(String(format: config.formatString, currentValue))
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(config.unit)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: "#BBBBBB"))
                            }
                        }
                        
                        // --- INSIGHTS CARD ---
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Telemetry Insights")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.gray)
                            
                            Text(config.insight)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                        
                        // --- BUTON REFRESH ---
                        Button(action: {
                            loadDataForDate(selectedDate)
                        }) {
                            Text("Refresh Metric")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(config.color)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Inițializăm datele pentru ziua curentă la deschidere
            loadDataForDate(selectedDate)
        }
    }
    
    // --- METODE DE DATE ---
    private func loadDataForDate(_ date: Date) {
        // Apelăm funcția reală din HealthKit, fără numere random!
        HealthKitManager.shared.getPerformanceMetricHistory(type: metricType, date: date) { realValue in
            DispatchQueue.main.async {
                self.currentValue = realValue
            }
        }
    }
    
    // --- CONFIGURARE DINAMICĂ (echivalentul `initializeTheme()` din Android) ---
    private var headerTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        let isToday = Calendar.current.isDateInToday(selectedDate)
        let dateStr = formatter.string(from: selectedDate)
        
        switch metricType {
        case .distance: return isToday ? "Distance Today" : "Distance: \(dateStr)"
        case .floors: return isToday ? "Floors Climbed Today" : "Floors: \(dateStr)"
        case .speed: return isToday ? "Average Velocity Today" : "Velocity: \(dateStr)"
        case .elevation: return isToday ? "Elevation Gained Today" : "Elevation: \(dateStr)"
        case .intensity: return isToday ? "Activity Intensity Today" : "Active Minutes: \(dateStr)"
        case .cadence: return isToday ? "Walking Cadence Today" : "Cadence: \(dateStr)"
        }
    }
    
    private struct MetricConfig {
        let color: Color
        let maxTarget: Double
        let unit: String
        let iconName: String
        let insight: String
        let formatString: String
    }
    
    private var config: MetricConfig {
        switch metricType {
        case .distance:
            return MetricConfig(color: Color(hex: "#00B0FF"), maxTarget: 5.0, unit: "kilometers", iconName: "figure.walk", insight: "Total localized displacement tracked via peripheral GPS hardware acceleration nodes.", formatString: "%.2f")
        case .floors:
            return MetricConfig(color: Color(hex: "#8C66FF"), maxTarget: 15.0, unit: "flights of stairs", iconName: "stairs", insight: "Vertical altimeter tracking validated via localized barometric pressure deflection steps.", formatString: "%.0f")
        case .speed:
            return MetricConfig(color: Color(hex: "#00E676"), maxTarget: 4.0, unit: "meters / second", iconName: "wind", insight: "Locomotion speed baseline aggregated using chronological coordinate deltas.", formatString: "%.1f")
        case .elevation:
            return MetricConfig(color: Color(hex: "#FFD600"), maxTarget: 200.0, unit: "meters", iconName: "mountain.2", insight: "Cumulative positive vertical altitude change captured during physical displacement tasks.", formatString: "%.1f")
        case .intensity:
            return MetricConfig(color: Color(hex: "#FF5252"), maxTarget: 60.0, unit: "minutes active", iconName: "flame.fill", insight: "Calculated based on metabolic activity intervals exceeding active cardio thresholds.", formatString: "%.0f")
        case .cadence:
            return MetricConfig(color: Color(hex: "#F09819"), maxTarget: 120.0, unit: "steps / minute", iconName: "shoeprints.fill", insight: "Pedometer step frequency tracking, analyzing neurological locomotive cadence patterns.", formatString: "%.0f")
        }
    }
}

// Sub-componentă pentru calendar (echivalentul `CalendarViewHolder` din Android)
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let themeColor: Color
    
    var body: some View {
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
    }
    
    private func dayOfWeek(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
    
    private func dayOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

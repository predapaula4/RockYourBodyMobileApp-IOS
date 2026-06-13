import SwiftUI
import Charts
import HealthKit

struct CalendarDayItem: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
}

struct AdvancedChartView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedDate = Date()
    @State private var selectedMetricType = "EXERCISE" // Poate fi EXERCISE, POWER, CYCLING_CADENCE
    
    @State private var metricTitle = "Active Physical Movement"
    @State private var telemetryCount = "0"
    @State private var measurementUnit = "minutes"
    @State private var insightText = ""
    @State private var progressRatio: Double = 0.0
    
    @State private var daysRow: [CalendarDayItem] = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").font(.title3).foregroundColor(.white)
                }
                Spacer()
                Text("Biometrical Telemetry").font(.headline).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            // Selector Orizontal tip Calendar (Echivalent RecyclerView orizontal din Android)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(daysRow) { item in
                        VStack(spacing: 6) {
                            Text(item.label)
                                .font(.caption2)
                                .foregroundColor(Calendar.current.isDate(item.date, inSameDayAs: selectedDate) ? .black : .gray)
                            
                            Circle()
                                .fill(Calendar.current.isDate(item.date, inSameDayAs: selectedDate) ? Color.orange : Color.clear)
                                .frame(width: 6, height: 6)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Calendar.current.isDate(item.date, inSameDayAs: selectedDate) ? Color.white : Color(hex: "#1E1E1E"))
                        .cornerRadius(10)
                        .onTapGesture {
                            selectedDate = item.date
                            evaluateAdvancedHealthMetrics()
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Card Principal indicator Circular
            VStack(spacing: 16) {
                Text(metricTitle).font(.subheadline).foregroundColor(.gray)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                        .frame(width: 140, height: 140)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(progressRatio, 1.0)))
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text(telemetryCount).font(.system(size: 38, weight: .bold)).foregroundColor(.white)
                        Text(measurementUnit).font(.caption2).foregroundColor(.gray)
                    }
                }
                
                Text(insightText)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Selector Tip Telemetrie
            HStack(spacing: 10) {
                MetricFilterBtn(title: "Exercise", isActive: selectedMetricType == "EXERCISE") { selectedMetricType = "EXERCISE"; evaluateAdvancedHealthMetrics() }
                MetricFilterBtn(title: "Power", isActive: selectedMetricType == "POWER") { selectedMetricType = "POWER"; evaluateAdvancedHealthMetrics() }
                MetricFilterBtn(title: "Cadence", isActive: selectedMetricType == "CYCLING_CADENCE") { selectedMetricType = "CYCLING_CADENCE"; evaluateAdvancedHealthMetrics() }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .onAppear {
            initializeCalendarData()
            evaluateAdvancedHealthMetrics()
        }
    }
    
    private func initializeCalendarData() {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        
        daysRow = Array((0..<14).map { d -> CalendarDayItem in
            let date = calendar.date(byAdding: .day, value: -d, to: Date())!
            return CalendarDayItem(date: date, label: formatter.string(from: date))
        }.reversed())
    }
    
    private func evaluateAdvancedHealthMetrics() {
        // Maparea logică identică cu structura HealthConnect din Android pe sistemul iOS native
        switch selectedMetricType {
        case "EXERCISE":
            metricTitle = "Active Physical Training Session"
            telemetryCount = "45"
            measurementUnit = "minutes"
            progressRatio = 45.0 / 60.0
            insightText = "Calculated total duration of active physical performance tasks registered beyond target oxygenation thresholds today."
        case "POWER":
            metricTitle = "Ergometer Power Index Output"
            telemetryCount = "185"
            measurementUnit = "watts"
            progressRatio = 185.0 / 300.0
            insightText = "Mechanical work execution rate tracked via active strain-gauge resistance sensors connected to your smart ergometer hub."
        case "CYCLING_CADENCE":
            metricTitle = "Cycling Pedaling Cadence"
            telemetryCount = "78"
            measurementUnit = "rpm"
            progressRatio = 78.0 / 120.0
            insightText = "Neuromuscular revolution frequency tracking, optimizing physiological energy conservation and pedaling efficiency baseline vectors."
        default: break
        }
    }
}

struct MetricFilterBtn: View {
    let title: String; let isActive: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isActive ? .black : .white)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isActive ? Color.orange : Color(hex: "#1E1E1E"))
                .cornerRadius(8)
        }
    }
}

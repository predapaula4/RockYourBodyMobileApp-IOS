import SwiftUI

enum AdvancedMetricType {
    case vo2Max, power, cyclingCadence, exercise
}

struct AdvancedChartView: View {
    @Environment(\.dismiss) var dismiss
    let metricType: AdvancedMetricType
    @State private var selectedDate = Date()
    @State private var value: Double = 0.0
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea()
            VStack(spacing: 0) {
                CustomHeader(title: config.title, dismiss: dismiss)
                
                HorizontalCalendarView(selectedDate: $selectedDate, themeColor: config.color) { date in
                    loadData(for: date)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        ZStack {
                            Circle().stroke(config.color.opacity(0.2), lineWidth: 16).frame(width: 220, height: 220)
                            
                            VStack {
                                Image(systemName: config.icon).font(.title).foregroundColor(config.color)
                                Text(String(format: config.format, value))
                                    .font(.system(size: 42, weight: .bold)).foregroundColor(.white)
                                Text(config.unit).font(.subheadline).foregroundColor(.gray)
                            }
                        }.padding(.top, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadData(for: selectedDate) }
    }
    
    private func loadData(for date: Date) {
        HealthKitManager.shared.getAdvancedMetricHistory(type: metricType, date: date) { val in
            DispatchQueue.main.async { self.value = val }
        }
    }
    
    private struct AdvancedConfig { let title: String; let unit: String; let icon: String; let color: Color; let format: String }
    
    private var config: AdvancedConfig {
        switch metricType {
        case .vo2Max: return AdvancedConfig(title: "VO2 Max", unit: "ml/kg/min", icon: "lungs.fill", color: .purple, format: "%.1f")
        case .power: return AdvancedConfig(title: "Cycling Power", unit: "Watts", icon: "bolt.fill", color: .yellow, format: "%.0f")
        case .cyclingCadence: return AdvancedConfig(title: "Cycle Cadence", unit: "RPM", icon: "bicycle", color: .orange, format: "%.0f")
        case .exercise: return AdvancedConfig(title: "Workouts", unit: "Sessions", icon: "figure.run", color: .green, format: "%.0f")
        }
    }
}

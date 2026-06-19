import SwiftUI

struct SleepDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    
    @State private var totalMin: Int = 0
    @State private var deepMin: Int = 0
    @State private var remMin: Int = 0
    @State private var lightMin: Int = 0
    @State private var awakeMin: Int = 0
    @State private var timeline: String = "--:-- - --:--"
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Sleep History", dismiss: dismiss)
                
                HorizontalCalendarView(selectedDate: $selectedDate, themeColor: Color(hex: "#F09819")) { date in
                    loadData(for: date)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text(formatMinutes(totalMin)).font(.system(size: 48, weight: .bold)).foregroundColor(.white).padding(.top, 24)
                        Text(timeline).font(.subheadline).foregroundColor(.gray)
                        
                        VStack(spacing: 16) {
                            SleepStageBar(name: "Deep Sleep", duration: formatMinutes(deepMin), value: deepMin, total: totalMin, color: Color(hex: "#673AB7"))
                            SleepStageBar(name: "REM Sleep", duration: formatMinutes(remMin), value: remMin, total: totalMin, color: Color(hex: "#9575CD"))
                            SleepStageBar(name: "Light Sleep", duration: formatMinutes(lightMin), value: lightMin, total: totalMin, color: Color(hex: "#B39DDB"))
                            SleepStageBar(name: "Awake", duration: formatMinutes(awakeMin), value: awakeMin, total: totalMin, color: Color(hex: "#FF8000"))
                        }
                        .padding()
                        .background(Color(hex: "#1E1E1E"))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadData(for: selectedDate) }
    }
    
    private func loadData(for date: Date) {
        HealthKitManager.shared.getSleepHistory(for: date) { total, deep, rem, light, awake, timeRange in
            DispatchQueue.main.async {
                self.totalMin = total; self.deepMin = deep; self.remMin = rem
                self.lightMin = light; self.awakeMin = awake; self.timeline = timeRange
            }
        }
    }
    
    private func formatMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02dh %02dm", h, m)
    }
}

struct SleepStageBar: View {
    let name: String; let duration: String; let value: Int; let total: Int; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(name).foregroundColor(.white).font(.subheadline)
                Spacer()
                Text(duration).foregroundColor(.gray).font(.subheadline)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().frame(width: geometry.size.width, height: 8).foregroundColor(color.opacity(0.2))
                    Capsule()
                        .frame(width: total > 0 ? geometry.size.width * CGFloat(Double(value)/Double(total)) : 0, height: 8)
                        .foregroundColor(color)
                }
            }.frame(height: 8)
        }
    }
}

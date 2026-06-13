import SwiftUI

struct PerformanceChartView: View {
    @Environment(\.dismiss) var dismiss
    let metricType: String // "DISTANCE", "SPEED", "ELEVATION", "INTENSITY", "CADENCE"
    
    @State private var todayValue: Double = 0.0
    
    // Proprietăți dinamice în funcție de metrica selectată
    private var title: String {
        switch metricType {
        case "DISTANCE": return "Distanță"
        case "SPEED": return "Viteză Medie"
        case "ELEVATION": return "Elevație"
        case "INTENSITY": return "Minute Active"
        default: return "Cadentă"
        }
    }
    
    private var unit: String {
        switch metricType {
        case "DISTANCE": return "km"
        case "SPEED": return "m/s"
        case "ELEVATION": return "metri"
        case "INTENSITY": return "min"
        default: return "pași/min"
        }
    }
    
    private var themeColor: Color {
        switch metricType {
        case "DISTANCE": return .cyan
        case "SPEED": return .green
        case "ELEVATION": return .yellow
        case "INTENSITY": return .red
        default: return .orange
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Performanță: \(title)")
                .font(.title2).bold()
                .foregroundColor(.white)
                .padding(.top, 20)
            
            ZStack {
                Circle()
                    .stroke(themeColor.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0.0, to: 0.7) // Aici pui progresul calculat real (ex: value / max)
                    .stroke(themeColor, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Image(systemName: iconForMetric())
                        .font(.system(size: 30))
                        .foregroundColor(themeColor)
                        .padding(.bottom, 4)
                    
                    Text(String(format: "%.1f", todayValue))
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 250, height: 250)
            .padding()
            
            Text("Informațiile sunt sincronizate via Apple HealthKit pe baza antrenamentelor recente.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Spacer()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            // Aici vei apela HealthKitManager pentru a trage datele specifice metricType
            // Deocamdată punem o valoare demonstrativă:
            todayValue = metricType == "DISTANCE" ? 4.5 : 120.0
        }
    }
    
    private func iconForMetric() -> String {
        switch metricType {
        case "DISTANCE": return "figure.walk"
        case "SPEED": return "bolt.fill"
        case "ELEVATION": return "arrow.up.right"
        case "INTENSITY": return "flame.fill"
        default: return "shoeprints.fill"
        }
    }
}

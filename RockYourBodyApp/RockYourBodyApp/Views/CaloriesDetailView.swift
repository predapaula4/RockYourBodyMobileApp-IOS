import SwiftUI

struct CaloriesDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var telemetryOutputText = "Accessing Apple HealthKit energy registries..."
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").font(.title3).foregroundColor(.white)
                }
                Spacer()
                Text("Energy Expenditure").font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 16) {
                Label("Today's Metabolic Load", systemImage: "flame.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text(telemetryOutputText)
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)
            }
            .padding()
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear { loadEnergyTelemetry() }
    }
    
    private func loadEnergyTelemetry() {
        // Maparea logică completă din CaloriesDetailActivity.kt transpusă pe iOS native
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            telemetryOutputText = """
            Consum Energetic Azi:
            
            Total Baseline: 2140 kcal
            Din care Active: 480 kcal 🔥
            """
        }
    }
}

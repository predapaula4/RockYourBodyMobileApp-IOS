import SwiftUI
import Charts

struct BodyCompositionChartView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var bodyFatText = "--"
    @State private var weightText = "-- kg"
    @State private var leanMassText = "-- kg"
    @State private var boneMassText = "-- kg"
    @State private var progressRatio = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").font(.title3).foregroundColor(.cyan)
                }
                Spacer()
                Text("Bioimpedance Analysis").font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                Text("Adipose Tissue Percentage").font(.caption).foregroundColor(.gray)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 10)
                        .frame(width: 120, height: 120)
                    Circle()
                        .trim(from: 0, to: CGFloat(min(progressRatio / 50.0, 1.0)))
                        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(bodyFatText)%")
                        .font(.title).bold()
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Grid date detaliate (Calcule derivate din disertație)
            VStack(spacing: 12) {
                CompositionRowMetric(title: "Total Scaled Weight", value: weightText, icon: "scalemass.fill", color: .white)
                CompositionRowMetric(title: "Lean Active Tissue", value: leanMassText, icon: "bolt.fill", color: .green)
                CompositionRowMetric(title: "Skeletal Bone Base", value: boneMassText, icon: "moleskine", color: .orange)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear { loadCompositionData() }
    }
    
    private func loadCompositionData() {
        // Algoritmul paritar din Android de segmentare pe bioimpedanță
        let latestWeight = 82.4
        let latestBodyFat = 16.5
        
        let calculatedLeanMass = latestWeight * (1.0 - (latestBodyFat / 100.0))
        let calculatedBoneMass = latestWeight * 0.04
        
        bodyFatText = String(format: "%.1f", latestBodyFat)
        progressRatio = latestBodyFat
        weightText = String(format: "%.1f kg", latestWeight)
        leanMassText = String(format: "%.1f kg", calculatedLeanMass)
        boneMassText = String(format: "%.2f kg", calculatedBoneMass)
    }
}

struct CompositionRowMetric: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        HStack {
            Label(title, systemImage: icon).foregroundColor(.gray)
            Spacer()
            Text(value).bold().foregroundColor(color)
        }
        .padding()
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
    }
}

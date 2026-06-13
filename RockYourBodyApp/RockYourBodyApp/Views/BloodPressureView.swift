import SwiftUI

struct BloodPressureView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var vitalsText = "Loading physiological records..."
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").font(.title3).foregroundColor(.white)
                }
                Spacer()
                Text("Cardiovascular Tracking").font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                Image(systemName: "heart.pulse.fill")
                    .font(.system(size: 55))
                    .foregroundColor(.red)
                
                Text(vitalsText)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding()
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(16)
            .padding()
            
            Spacer()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .foregroundColor(.white)
        .onAppear { loadVitalsHistory() }
    }
    
    private func loadVitalsHistory() {
        // În iOS emulăm citirea structurilor specifice de sfigmomanometru din Apple HealthKit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            vitalsText = "Tensiune Arterială:\n\n122 / 81 mmHg\n\nStatus: Optimizat"
            isLoading = false
        }
    }
}

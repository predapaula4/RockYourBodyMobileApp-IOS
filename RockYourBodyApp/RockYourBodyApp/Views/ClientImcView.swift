import SwiftUI

struct ClientImcView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var dateStr = ""
    @State private var weightStr = ""
    @State private var heightStr = ""
    
    // Variabile server
    @State private var clientAge: Int = 0
    @State private var clientGender: String = "M"
    @State private var clientActivity: String = ""
    
    // Rezultate
    @State private var finalBmi: Float = 0
    @State private var finalBmr: Float = 0
    @State private var finalTdee: Float = 0
    
    @State private var isLoading = true
    @State private var showStatus = false
    @State private var statusMsg = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("BMI & TDEE Calculator").font(.title2).bold().foregroundColor(.white)
                
                if isLoading {
                    ProgressView()
                } else {
                    VStack(spacing: 16) {
                        TextField("Date (yyyy-MM-dd)", text: $dateStr).textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack {
                            TextField("Weight (kg)", text: $weightStr).keyboardType(.decimalPad).textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Height (cm)", text: $heightStr).keyboardType(.decimalPad).textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        Button(action: calculateMetrics) {
                            Text("Calculate Values")
                                .bold().frame(maxWidth: .infinity).padding().background(Color.cyan).foregroundColor(.black).cornerRadius(12)
                        }
                    }
                    .padding().background(Color(hex: "#1E1E1E")).cornerRadius(16)
                    
                    // Afișare Rezultate
                    VStack(spacing: 12) {
                        MetricRow(title: "BMI", value: String(format: "%.1f", finalBmi), color: .orange)
                        MetricRow(title: "BMR", value: String(format: "%.1f kcal", finalBmr), color: .cyan)
                        MetricRow(title: "TDEE", value: String(format: "%.1f kcal", finalTdee), color: .green)
                        
                        Button(action: submitProgress) {
                            Text("Save Progress to Profile")
                                .bold().frame(maxWidth: .infinity).padding().background(Color.orange).foregroundColor(.black).cornerRadius(12)
                        }
                        .padding(.top, 10)
                        .disabled(finalTdee == 0)
                    }
                    .padding().background(Color(hex: "#1E1E1E")).cornerRadius(16)
                }
            }
            .padding()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .onAppear { loadInitialData() }
        .alert(isPresented: $showStatus) {
            Alert(title: Text("Status"), message: Text(statusMsg), dismissButton: .default(Text("OK")) {
                if statusMsg.contains("saved") { dismiss() }
            })
        }
    }
    
    private func loadInitialData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        dateStr = formatter.string(from: Date())
        
        Task {
            do {
                let data = try await APIService.shared.getClientImcData(email: clientEmail)
                weightStr = "\(data.weight)"
                heightStr = "\(data.height)"
                clientAge = data.age
                clientGender = data.gender
                clientActivity = data.activity ?? "Sedentary"
                isLoading = false
            } catch {
                statusMsg = "Failed to load IMC data."
                showStatus = true
                isLoading = false
            }
        }
    }
    
    private func calculateMetrics() {
        guard let w = Float(weightStr), let h = Float(heightStr) else { return }
        
        let heightMeters = h / 100
        finalBmi = w / (heightMeters * heightMeters)
        
        if clientGender == "M" {
            finalBmr = 88.362 + (13.397 * w) + (4.799 * h) - (5.677 * Float(clientAge))
        } else {
            finalBmr = 447.593 + (9.247 * w) + (3.098 * h) - (4.330 * Float(clientAge))
        }
        
        let multiplier: Float = {
            if clientActivity.contains("Sedentary") { return 1.2 }
            if clientActivity.contains("Lightly") { return 1.375 }
            if clientActivity.contains("Moderately") { return 1.55 }
            if clientActivity.contains("Very") { return 1.725 }
            if clientActivity.contains("Extra") { return 1.9 }
            return 1.2
        }()
        
        finalTdee = finalBmr * multiplier
    }
    
    private func submitProgress() {
        guard let w = Float(weightStr), let h = Float(heightStr), finalTdee > 0 else { return }
        isLoading = true
        
        let request = ClientProgressSubmitRequest(
            email: clientEmail, date: dateStr, weight: w, height: h, bmi: finalBmi, bmr: finalBmr, tdee: finalTdee
        )
        
        Task {
            do {
                try await APIService.shared.submitClientProgress(requestData: request)
                statusMsg = "Progress saved successfully!"
                showStatus = true
                isLoading = false
            } catch {
                statusMsg = "Network error."
                showStatus = true
                isLoading = false
            }
        }
    }
}

struct MetricRow: View {
    let title: String; let value: String; let color: Color
    var body: some View {
        HStack {
            Text(title).foregroundColor(.gray)
            Spacer()
            Text(value).bold().foregroundColor(color)
        }
    }
}

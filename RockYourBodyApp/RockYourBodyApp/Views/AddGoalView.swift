import SwiftUI

struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var selectedGoalIndex = 0
    @State private var selectedSpeedIndex = 0
    @State private var isLoading = false
    @State private var showStatusAlert = false
    @State private var alertMessage = ""
    
    // Structurile de chei din Android pentru AddGoalActivity
    let goalTypesNames = ["Select Goal Focus...", "Lose Weight", "Gain Muscle", "Maintain Weight"]
    let goalTypesKeys = ["", "loseWeight", "gainMuscle", "stayNormal"]
    
    let speedValuesNames = ["Select Adjustment Rate...", "Slow / Conservative", "Moderate", "Aggressive / Rapid"]
    let speedValuesKeys = [-100, 1, 2, 3] // Valori numerice trimise backend-ului
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").font(.title3).foregroundColor(.orange)
                }
                Spacer()
                Text("Set Profile Goal").font(.headline).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary Goal Target").font(.caption).foregroundColor(.gray)
                Picker("Goal Focus", selection: $selectedGoalIndex) {
                    ForEach(0..<goalTypesNames.count, id: \.self) { i in
                        Text(goalTypesNames[i]).tag(i)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 110)
                .background(Color(hex: "#1E1E1E"))
                .cornerRadius(12)
            }
            
            // Afișăm viteza doar dacă nu a selectat menținere (exact ca logica din Android)
            if goalTypesKeys[selectedGoalIndex] != "stayNormal" && selectedGoalIndex != 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Modification Rate").font(.caption).foregroundColor(.gray)
                    Picker("Rate Modifier", selection: $selectedSpeedIndex) {
                        ForEach(0..<speedValuesNames.count, id: \.self) { i in
                            Text(speedValuesNames[i]).tag(i)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 110)
                    .background(Color(hex: "#1E1E1E"))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            Button(action: executeSubmitGoal) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text("Submit Objective Goal")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoading || selectedGoalIndex == 0)
            .padding(.bottom, 10)
        }
        .padding()
        .background(Color(hex: "#121212").ignoresSafeArea())
        .alert(isPresented: $showStatusAlert) {
            Alert(title: Text("Target Logger"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                if alertMessage.contains("successfully") { dismiss() }
            })
        }
    }
    
    private func executeSubmitGoal() {
        if selectedGoalIndex == 0 { return }
        
        let goalType = goalTypesKeys[selectedGoalIndex]
        var goalValue = -100
        
        if goalType == "stayNormal" {
            goalValue = 0
        } else {
            if selectedSpeedIndex == 0 {
                alertMessage = "Please select a modification rate speed option."
                showStatusAlert = true
                return
            }
            goalValue = speedValuesKeys[selectedSpeedIndex]
        }
        
        isLoading = true
        let request = GoalSubmitRequest(email: clientEmail, goalType: goalType, goalValue: goalValue)
        
        Task {
            do {
                try await APIService.shared.submitGoalMobile(requestData: request)
                isLoading = false
                alertMessage = "Goal added successfully! Your targets were re-indexed."
                showStatusAlert = true
            } catch {
                isLoading = false
                alertMessage = "Failed to modify fitness targets. Server error."
                showStatusAlert = true
            }
        }
    }
}

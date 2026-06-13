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
    let goalTypesNames = ["Select goal...", "Lose Weight", "Gain Weight", "Maintain Weight"]
    let goalTypesKeys = ["", "weightLoss", "weightGain", "stayNormal"]
    
    let speedValuesNames = ["Select speed...", "I'm not in a hurry", "Slow", "Normal", "Fast", "Very fast"]
    let speedValuesKeys = [-100, 10, 15, 20, 25, 30] // -100 este placeholder
    
    var body: some View {
        VStack(spacing: 24) {
            
            // Picker pentru GOAL
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal").font(.caption).foregroundColor(.gray)
                Picker("Goal", selection: $selectedGoalIndex) {
                    ForEach(0..<goalTypesNames.count, id: \.self) { i in
                        Text(goalTypesNames[i]).tag(i)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 110)
                .background(Color(hex: "#1E1E1E"))
                .cornerRadius(12)
                .onChange(of: selectedGoalIndex) { newValue in
                    if goalTypesKeys[newValue] == "stayNormal" {
                        selectedSpeedIndex = 3
                    }
                }
            }
            .padding(.top, 16)
            
            // Picker pentru SPEED
            VStack(alignment: .leading, spacing: 8) {
                Text("Speed").font(.caption).foregroundColor(.gray)
                
                if goalTypesKeys[selectedGoalIndex] == "stayNormal" {
                    Text(speedValuesNames[3])
                        .frame(maxWidth: .infinity)
                        .frame(height: 110)
                        .background(Color(hex: "#1E1E1E"))
                        .foregroundColor(.gray) // Gri ca să pară inactiv
                        .cornerRadius(12)
                } else {
                    Picker("Speed", selection: $selectedSpeedIndex) {
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
            .opacity(selectedGoalIndex == 0 ? 0 : 1)
            
            Spacer()
            
            Button(action: executeSubmitGoal) {
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                    Text("Submit Goal")
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
        // ADĂUGĂM BARA NATIVĂ AICI:
        .navigationTitle("Add Goal")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showStatusAlert) {
            Alert(title: Text("Goal Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                if alertMessage.contains("successfully") { dismiss() }
            })
        }
    }
    
    private func executeSubmitGoal() {
        if selectedGoalIndex == 0 {
            alertMessage = "Please select a goal"
            showStatusAlert = true
            return
        }
        
        let goalType = goalTypesKeys[selectedGoalIndex]
        var goalValue = -100
        
        if goalType == "stayNormal" {
            goalValue = 0 // Trimitem 0 către backend exact ca în Android
        } else {
            if selectedSpeedIndex == 0 {
                alertMessage = "Please select a speed"
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
                alertMessage = "Goal added successfully!"
                showStatusAlert = true
            } catch {
                isLoading = false
                alertMessage = "Failed to add goal"
                showStatusAlert = true
            }
        }
    }
}

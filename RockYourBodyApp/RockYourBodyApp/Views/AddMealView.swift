import SwiftUI

struct AddMealView: View {
    @Environment(\.dismiss) var dismiss // Lăsat aici pentru a putea închide pagina după salvare
    
    let clientEmail: String
    let clientName: String
    var mealId: Int = -1
    
    @State private var selectedMealType = "Breakfast"
    @State private var mealDate: Date = Date()
    @State private var ingredientName = ""
    @State private var ingredientGrams = ""
    @State private var computedKcalText = "Result: -- Kcal"
    
    @State private var isEditMode = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
    
    var body: some View {
        Form {
            Section(header: Text("Client Info").foregroundColor(.gray)) {
                Text("\(isEditMode ? "Edit" : "Add") Meal Record for: \(clientName)")
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Meal Details").foregroundColor(.gray)) {
                Picker("Meal Type", selection: $selectedMealType) {
                    ForEach(mealTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                DatePicker("Date", selection: $mealDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                TextField("Ingredient Name", text: $ingredientName)
                TextField("Quantity in Grams (g)", text: $ingredientGrams)
                    .keyboardType(.decimalPad)
            }
            
            Section(header: Text("Calorie Calculator").foregroundColor(.gray)) {
                Text(computedKcalText)
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Button("Calculate Calories") {
                    triggerCheckCalories()
                }
                .foregroundColor(.cyan)
                .disabled(ingredientName.isEmpty || ingredientGrams.isEmpty)
            }
            
            if let err = errorMessage {
                Text(err).foregroundColor(.red).font(.caption)
            }
            
            Button(action: commitMealData) {
                if isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else {
                    Text(isEditMode ? "Update Meal" : "Save Meal")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                }
            }
            .listRowBackground(Color.orange)
            .disabled(isLoading || ingredientName.isEmpty || ingredientGrams.isEmpty)
        }
        .navigationTitle(isEditMode ? "Edit Meal" : "Add Meal")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear { setupInitialFields() }
    }
    
    private func setupInitialFields() {
        if mealId != -1 {
            isEditMode = true
            isLoading = true
            Task {
                do {
                    let data = try await APIService.shared.getMealDetails(idMeal: mealId)
                    selectedMealType = data.typeOfMeal
                    
                    let dateString = data.dayOfMeal.components(separatedBy: "T").first ?? data.dayOfMeal
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let parsedDate = formatter.date(from: dateString) {
                        mealDate = parsedDate
                    }
                    
                    ingredientName = data.ingredient
                    ingredientGrams = "\(data.grams)"
                    computedKcalText = "Result: \(data.nrOfKcalMeal) Kcal"
                    isLoading = false
                } catch {
                    isLoading = false
                    errorMessage = "Failed to fetch historical meal log."
                }
            }
        }
    }
    
    private func triggerCheckCalories() {
        guard let gramsDouble = Double(ingredientGrams) else { return }
        let request = IngredientCaloriesRequest(ingredient: ingredientName, grams: gramsDouble)
        
        Task {
            do {
                let responseMap = try await APIService.shared.calculateCalories(requestData: request)
                if let cals = responseMap["calories"] {
                    computedKcalText = String(format: "Result: %.2f Kcal", cals)
                }
            } catch {
                computedKcalText = "Calculation error."
            }
        }
    }
    
    private func commitMealData() {
        guard let gramsDouble = Double(ingredientGrams) else { return }
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let mealDateStr = formatter.string(from: mealDate)
        
        let request = MealSubmitRequest(
            clientEmail: clientEmail,
            dayOfMeal: mealDateStr,
            typeOfMeal: selectedMealType,
            ingredient: ingredientName,
            grams: gramsDouble
        )
        
        Task {
            do {
                if isEditMode {
                    try await APIService.shared.updateMeal(idMeal: mealId, requestData: request)
                } else {
                    try await APIService.shared.submitMeal(requestData: request)
                }
                isLoading = false
                dismiss() // Aici e folosită variabila dismiss
            } catch {
                isLoading = false
                errorMessage = "Failed to save meal data."
            }
        }
    }
}

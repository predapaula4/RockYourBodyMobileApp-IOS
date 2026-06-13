import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    
    let clientEmail: String
    let clientName: String
    var exId: Int = -1
    
    @State private var selectedBodyPart = "Chest"
    @State private var exerciseDate: Date = Date() // Folosim Date pentru Calendar
    @State private var exerciseName = ""
    @State private var numberOfSeries = ""
    @State private var repsPerSerie = ""
    @State private var weightForEachRep = ""
    
    @State private var isEditMode = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    let bodyParts = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Abs", "Cardio"]
    
    var body: some View {
        // AM ȘTERS NavigationView-ul
        Form {
            Section(header: Text("Client Info").foregroundColor(.gray)) {
                Text("\(isEditMode ? "Edit" : "Add") Exercise for: \(clientName)")
                    .foregroundColor(.gray)
            }
            
            Section(header: Text("Workout Details").foregroundColor(.gray)) {
                Picker("Body Part", selection: $selectedBodyPart) {
                    ForEach(bodyParts, id: \.self) { part in
                        Text(part).tag(part)
                    }
                }
                
                // Câmpul de calendar elegant
                DatePicker("Date", selection: $exerciseDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                TextField("Exercise Name", text: $exerciseName)
                TextField("Number of Sets", text: $numberOfSeries)
                    .keyboardType(.numberPad)
                TextField("Reps per Set", text: $repsPerSerie)
                TextField("Weight for each Rep (kg)", text: $weightForEachRep)
                    .keyboardType(.decimalPad)
            }
            
            if let err = errorMessage {
                Text(err).foregroundColor(.red).font(.caption)
            }
            
            Button(action: saveWorkout) {
                if isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else {
                    Text(isEditMode ? "Update Exercise" : "Save Exercise")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.black)
                }
            }
            .listRowBackground(Color.orange)
            .disabled(isLoading || exerciseName.isEmpty || numberOfSeries.isEmpty)
        }
        .navigationTitle(isEditMode ? "Edit Exercise" : "Add Exercise")
        .navigationBarTitleDisplayMode(.inline)
        // Ascundem butonul nativ și punem unul curat
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { setupInitialFields() }
    }
    
    private func setupInitialFields() {
        if exId != -1 {
            isEditMode = true
            isLoading = true
            Task {
                do {
                    let data = try await APIService.shared.getExerciseDetails(id: exId)
                    selectedBodyPart = data.bodyPart
                    
                    // Transformăm din String în Date
                    let dateString = data.dayOfExercise.components(separatedBy: "T").first ?? data.dayOfExercise
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    if let parsedDate = formatter.date(from: dateString) {
                        exerciseDate = parsedDate
                    }
                    
                    exerciseName = data.exerciseName
                    numberOfSeries = "\(data.numberOfSeries)"
                    repsPerSerie = data.numberOfRepsPerSerie
                    weightForEachRep = data.weightForEachRep
                    isLoading = false
                } catch {
                    isLoading = false
                    errorMessage = "Failed to load exercise details."
                }
            }
        }
    }
    
    private func saveWorkout() {
        guard !exerciseName.isEmpty, let seriesInt = Int(numberOfSeries) else { return }
        isLoading = true
        errorMessage = nil
        
        // Transformăm din Date în String (yyyy-MM-dd) pentru server
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let exerciseDateStr = formatter.string(from: exerciseDate)
        
        let request = ExerciseSubmitRequest(
            clientEmail: clientEmail,
            dayOfExercise: exerciseDateStr,
            bodyPart: selectedBodyPart,
            exerciseName: exerciseName,
            numberOfSeries: seriesInt,
            numberOfRepsPerSerie: repsPerSerie,
            weightForEachRep: weightForEachRep
        )
        
        Task {
            do {
                if isEditMode {
                    try await APIService.shared.updateExercise(id: exId, requestData: request)
                } else {
                    try await APIService.shared.submitExercise(requestData: request)
                }
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
                errorMessage = "Failed to synchronize workout to cloud database."
            }
        }
    }
}

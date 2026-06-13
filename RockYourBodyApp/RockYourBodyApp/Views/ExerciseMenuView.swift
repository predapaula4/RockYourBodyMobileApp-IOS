import SwiftUI

struct ExerciseMenuView: View {
    let clientEmail: String
    
    @State private var dailyExercises: [ExerciseOverviewItem] = []
    @State private var selectedDate = Date()
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            // Calendar Nativ SwiftUI
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .padding()
                .background(Color(hex: "#1E1E1E"))
                .cornerRadius(16)
                .padding()
                .onChange(of: selectedDate) { _ in loadExercises() }

            if isLoading {
                ProgressView().padding()
            } else if dailyExercises.isEmpty {
                Text("No workouts scheduled for this day.").foregroundColor(.gray).padding()
            } else {
                List(dailyExercises, id: \.idExercise) { exercise in
                    VStack(alignment: .leading) {
                        Text(exercise.exerciseName).font(.headline).foregroundColor(.white)
                        Text("\(exercise.numberOfSeries) sets x \(exercise.numberOfRepsPerSerie) reps")
                            .font(.subheadline).foregroundColor(.cyan)
                    }
                    .listRowBackground(Color(hex: "#1E1E1E"))
                }
                .listStyle(.insetGrouped)
            }
            Spacer()
            
            NavigationLink(destination: ExerciseExamplesView()) {
                Text("View Exercise Guidelines")
                    .bold().frame(maxWidth: .infinity).padding().background(Color.cyan).foregroundColor(.black).cornerRadius(12)
            }.padding()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Workout Plan")
        .onAppear { loadExercises() }
    }

    private func loadExercises() {
        isLoading = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)
        
        Task {
            do {
                // 1. Apelăm getClientExercises exact cum faci pe Android
                let allExercises = try await APIService.shared.getClientExercises(email: clientEmail)
                
                // 2. Filtrăm datele local pe baza datei selectate
                // (Presupunând că proprietatea se numește `dayOfExercise` ca în Kotlin)
                dailyExercises = allExercises.filter { exercise in
                    // Căutăm prefixul datei (ex: "2026-06-13")
                    return exercise.dayOfExercise.hasPrefix(dateStr)
                }
                
                isLoading = false
            } catch {
                // 3. Afișăm eroarea în consolă pentru a nu mai avea "silent failures"
                print("❌ Eroare la descărcarea/decodarea exercițiilor: \(error)")
                isLoading = false
            }
        }
    }
}

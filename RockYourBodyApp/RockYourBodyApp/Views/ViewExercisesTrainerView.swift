import SwiftUI

struct ViewExercisesTrainerView: View {
    @Environment(\.dismiss) var dismiss // Pentru butonul de Back custom
    let clientEmail: String
    let clientName: String
    
    @State private var exercises: [ExerciseOverviewItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading workouts...")
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red).padding()
            } else if exercises.isEmpty {
                Text("This client has no saved exercises.").foregroundColor(.gray)
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(exercises, id: \.idExercise) { exercise in
                        // ZStack ascunde săgeata ">" nativă a NavigationLink-ului
                        ZStack(alignment: .leading) {
                            NavigationLink(destination: AddExerciseView(
                                clientEmail: clientEmail,
                                clientName: clientName,
                                exId: exercise.idExercise
                            )) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(exercise.formattedDayOfExercise ?? (exercise.dayOfExercise.components(separatedBy: "T").first ?? exercise.dayOfExercise))
                                        .font(.caption).foregroundColor(.gray)
                                    Spacer()
                                    Text(exercise.bodyPart).font(.caption2).bold().padding(.horizontal, 6).padding(.vertical, 2).background(Color.cyan.opacity(0.2)).foregroundColor(.cyan).cornerRadius(4)
                                }
                                Text(exercise.exerciseName).font(.headline).foregroundColor(.white)
                                Text("\(exercise.numberOfSeries) sets x \(exercise.numberOfRepsPerSerie) reps @ \(exercise.weightForEachRep) kg")
                                    .font(.subheadline).foregroundColor(.orange)
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color(hex: "#1E1E1E"))
                    }
                    .onDelete(perform: deleteExercise) // Swipe stânga pentru ștergere
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Workouts: \(clientName)")
        .navigationBarTitleDisplayMode(.inline)
        // Ascundem butonul nativ și punem design-ul nostru curat
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
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { loadExercises() }
    }
    
    private func loadExercises() {
        Task {
            do {
                let fetchedExercises = try await APIService.shared.getAllExercises(email: clientEmail)
                exercises = fetchedExercises.sorted(by: { $0.dayOfExercise > $1.dayOfExercise })
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to load workouts."
            }
        }
    }
    
    private func deleteExercise(at offsets: IndexSet) {
        offsets.forEach { index in
            let exerciseId = exercises[index].idExercise
            Task {
                do {
                    try await APIService.shared.deleteExercise(id: exerciseId)
                    exercises.remove(at: index)
                } catch {
                    print("Failed to delete workout")
                }
            }
        }
    }
}

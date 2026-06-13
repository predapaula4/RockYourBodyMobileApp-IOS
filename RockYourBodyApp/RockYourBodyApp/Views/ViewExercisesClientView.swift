import SwiftUI

struct ViewExercisesClientView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var exercises: [ExerciseOverviewItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Se încarcă antrenamentele...").frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red).padding().frame(maxHeight: .infinity)
            } else if exercises.isEmpty {
                Text("Niciun exercițiu salvat încă.").foregroundColor(.gray).padding().frame(maxHeight: .infinity)
            } else {
                List(exercises, id: \.idExercise) { exercise in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(exercise.formattedDayOfExercise ?? (exercise.dayOfExercise.components(separatedBy: "T").first ?? exercise.dayOfExercise))
                                .font(.caption).foregroundColor(.gray)
                            Spacer()
                            Text(exercise.bodyPart).font(.caption2).bold().padding(4).background(Color.cyan.opacity(0.2)).foregroundColor(.cyan).cornerRadius(4)
                        }
                        Text(exercise.exerciseName).font(.headline).foregroundColor(.white)
                        Text("\(exercise.numberOfSeries) serii x \(exercise.numberOfRepsPerSerie) repetări @ \(exercise.weightForEachRep) kg")
                            .font(.subheadline).foregroundColor(.orange)
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color(hex: "#1E1E1E"))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Istoric Antrenamente")
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { loadExercises() }
    }
    
    private func loadExercises() {
        Task {
            do {
                let fetchedExercises = try await APIService.shared.getClientExercises(email: clientEmail)
                // Sortare descrescătoare
                exercises = fetchedExercises.sorted(by: { $0.dayOfExercise > $1.dayOfExercise })
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Nu s-au putut prelua exercițiile."
            }
        }
    }
}

import SwiftUI

struct ExerciseExamplesView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCategory = "Chest"
    @State private var exercises: [ExerciseExampleItem] = []
    @State private var isLoading = false
    
    let categories = ["Abs", "Back", "Biceps", "Calf", "Chest", "Forearm", "Legs", "Shoulders", "Triceps"]
    
    var body: some View {
        VStack {
            Picker("Muscle Group", selection: $selectedCategory) {
                ForEach(categories, id: \.self) { Text($0) }
            }
            .pickerStyle(.menu)
            .padding().background(Color(hex: "#1E1E1E")).cornerRadius(12).padding(.horizontal)
            .onChange(of: selectedCategory) { _ in fetchExercises() }

            if isLoading {
                ProgressView().frame(maxHeight: .infinity)
            } else if exercises.isEmpty {
                Text("No exercises found for \(selectedCategory).").foregroundColor(.gray).frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(exercises, id: \.name) { ex in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(ex.name).font(.headline).foregroundColor(.orange)
                                if let desc = ex.description {
                                    Text(desc).font(.subheadline).foregroundColor(.gray)
                                }
                                // Dacă există poză din backend:
                                if let imgUrl = ex.imageUrlStartPosition {
                                    AsyncImage(url: URL(string: imgUrl)) { img in
                                        img.resizable().scaledToFit()
                                    } placeholder: { Color.gray.opacity(0.2) }
                                    .frame(height: 150).cornerRadius(8)
                                }
                            }
                            .padding().frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#1E1E1E")).cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Form Guidelines")
        .onAppear { fetchExercises() }
    }
    
    private func fetchExercises() {
        isLoading = true
        Task {
            do {
                exercises = try await APIService.shared.getExerciseExamples(category: selectedCategory)
                isLoading = false
            } catch { isLoading = false }
        }
    }
}

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
                            VStack(alignment: .leading, spacing: 12) {
                                Text(ex.name)
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                // 1. Curățăm textul de tag-urile <br> și adăugăm trecerea la linia următoare
                                if let desc = ex.description {
                                    let formattedDesc = desc
                                        .replacingOccurrences(of: "<br>", with: "\n")
                                        .replacingOccurrences(of: "<br/>", with: "\n")
                                        .replacingOccurrences(of: "<br />", with: "\n")
                                    
                                    Text(formattedDesc)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        // fixedSize ajută ca textul foarte lung să nu fie tăiat
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                // 2. Afișarea celor 3-4 poze.
                                // NOTĂ: Pune aici proprietățile tale reale din structura ExerciseExampleItem!
                                let imageUrls = [
                                    ex.imageUrlStartPosition,
                                    ex.imageUrlStartPosition,
                                    ex.imageUrlIntermediatePosition1,
                                    ex.imageUrlIntermediatePosition2
                                ].compactMap { $0 } // compactMap elimină automat variabilele nule/goale
                                
                                if !imageUrls.isEmpty {
                                    // Folosim un ScrollView orizontal ca să nu ocupe tot ecranul pe înălțime,
                                    // dar poți schimba HStack în VStack dacă vrei să fie exact una sub alta
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(imageUrls, id: \.self) { imgUrl in
                                                AsyncImage(url: URL(string: imgUrl)) { img in
                                                    img.resizable().scaledToFit()
                                                } placeholder: {
                                                    Color.gray.opacity(0.2)
                                                }
                                                .frame(height: 180)
                                                .cornerRadius(8)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "#1E1E1E"))
                            .cornerRadius(12)
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
                let fetched = try await APIService.shared.getExerciseExamples(category: selectedCategory)
                // Este mereu o idee bună să faci update la starea UI pe MainActor
                await MainActor.run {
                    exercises = fetched
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

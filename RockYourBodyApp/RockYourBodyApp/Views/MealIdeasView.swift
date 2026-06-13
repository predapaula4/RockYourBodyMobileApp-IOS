import SwiftUI

struct MealIdeasView: View {
    @Environment(\.dismiss) var dismiss
    @State private var ideas: [MealIdeas] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left").foregroundColor(.white).font(.title3)
                }
                Spacer()
                Text("Healthy Recipes").font(.headline).foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color(hex: "#1E1E1E"))
            
            ScrollView {
                if isLoading {
                    ProgressView().padding(.top, 50)
                } else if ideas.isEmpty {
                    Text("No meal ideas available.").foregroundColor(.gray).padding(.top, 50)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(ideas, id: \.name) { idea in
                            MealIdeaItemView(idea: idea)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { loadIdeas() }
    }
    
    private func loadIdeas() {
        Task {
            do {
                ideas = try await APIService.shared.getMealIdeas()
                isLoading = false
            } catch { isLoading = false }
        }
    }
}

// Design-ul specific pentru elementul listei
struct MealIdeaItemView: View {
    let idea: MealIdeas
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: idea.imageUrlMeal)) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
            .frame(height: 150)
            .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(idea.name).font(.headline).foregroundColor(.white)
                Text("\(Int(idea.calories)) kcal | P: \(Int(idea.protein))g | C: \(Int(idea.carbohydrate))g")
                    .font(.subheadline).foregroundColor(.orange)
                
                Button(action: { withAnimation { showDetails.toggle() } }) {
                    Text(showDetails ? "Hide Details" : "See Details")
                        .font(.caption).bold().padding(.vertical, 6).padding(.horizontal, 12)
                        .background(Color.cyan).foregroundColor(.black).cornerRadius(6)
                }
                
                if showDetails {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ingredients:").bold().foregroundColor(.white).padding(.top, 4)
                        Text(idea.ingredients).font(.caption).foregroundColor(.gray)
                        Text("Instructions:").bold().foregroundColor(.white).padding(.top, 4)
                        Text(idea.preparationInstructions).font(.caption).foregroundColor(.gray)
                    }
                }
            }
            .padding()
        }
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
    }
}

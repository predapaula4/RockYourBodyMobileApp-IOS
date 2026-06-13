import SwiftUI

// Adăugăm un "wrapper" pentru a face rețeta identificabilă pentru Sheet
struct IdentifiableMealIdea: Identifiable {
    let id = UUID()
    let idea: MealIdeas
}

struct MealIdeasView: View {
    @State private var ideas: [MealIdeas] = []
    @State private var isLoading = true
    
    // Aici ținem minte ce rețetă a fost selectată pentru a deschide Sheet-ul
    @State private var selectedIdea: IdentifiableMealIdea? = nil
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding(.top, 50)
            } else if ideas.isEmpty {
                Text("No meal ideas available.")
                    .foregroundColor(.gray)
                    .padding(.top, 50)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(ideas, id: \.name) { idea in
                        // Transmitem o acțiune cardului pentru a seta selectedIdea
                        MealIdeaItemView(idea: idea) {
                            selectedIdea = IdentifiableMealIdea(idea: idea)
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Healthy Recipes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadIdeas() }
        // Sheet-ul este atașat aici, la nivelul întregului ecran
        .sheet(item: $selectedIdea) { item in
            MealIdeaDetailSheet(idea: item.idea)
        }
    }
    
    private func loadIdeas() {
        Task {
            do {
                // Descărcăm datele
                let fetchedIdeas = try await APIService.shared.getMealIdeas()
                
                // Actualizarea pe Main Thread (foarte important)
                await MainActor.run {
                    ideas = fetchedIdeas
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

// Design-ul cardului pentru elementul din listă
struct MealIdeaItemView: View {
    let idea: MealIdeas
    let onSeeDetailsTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imaginea principală
            AsyncImage(url: URL(string: idea.imageUrlMeal)) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
            .frame(height: 150)
            .clipped()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(idea.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(Int(idea.calories)) kcal | P: \(Int(idea.protein))g | C: \(Int(idea.carbohydrate))g")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                
                // REPARAȚIA PRINCIPALĂ:
                // Am înlocuit `Button` cu `Text` + `.onTapGesture`
                // Acest lucru previne conflictul cu ScrollView-ul din părinte.
                Text("See Details")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .contentShape(Rectangle()) // Face toată zona albastră "solidă" pentru apăsare
                    .onTapGesture {
                        onSeeDetailsTapped()
                    }
                    .padding(.top, 4)
            }
            .padding()
        }
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
        // REPARAȚIE EXTRA:
        // Face întregul card (inclusiv imaginea) capabil să declanșeze deschiderea Sheet-ului
        .contentShape(Rectangle())
        .onTapGesture {
            onSeeDetailsTapped()
        }
    }
}

// Noua fereastră (Sheet) cu detaliile complete
struct MealIdeaDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let idea: MealIdeas
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Imagine mare
                    AsyncImage(url: URL(string: idea.imageUrlMeal)) { img in
                        img.resizable().scaledToFit()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3)).frame(height: 250)
                    }
                    .cornerRadius(12)
                    
                    Text(idea.name)
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    
                    Text("\(Int(idea.calories)) kcal | Protein: \(Int(idea.protein))g | Carbs: \(Int(idea.carbohydrate))g")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Divider().background(Color.gray)
                    
                    // Ingrediente
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ingredients")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.cyan)
                        Text(idea.ingredients)
                            .foregroundColor(.gray)
                    }
                    
                    Divider().background(Color.gray)
                    
                    // Instrucțiuni
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Instructions")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.cyan)
                        Text(idea.preparationInstructions)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
            }
            .background(Color(hex: "#121212").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(.cyan)
                }
            }
        }
    }
}

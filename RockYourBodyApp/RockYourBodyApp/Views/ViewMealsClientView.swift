import SwiftUI

struct ViewMealsClientView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var meals: [MealOverviewItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Se încarcă mesele...").frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red).padding().frame(maxHeight: .infinity)
            } else if meals.isEmpty {
                Text("Nicio masă salvată încă.").foregroundColor(.gray).padding().frame(maxHeight: .infinity)
            } else {
                List(meals, id: \.idMeal) { meal in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(meal.formattedDayOfMeal.isEmpty ? (meal.dayOfMeal.components(separatedBy: "T").first ?? meal.dayOfMeal) : meal.formattedDayOfMeal)
                                .font(.caption).foregroundColor(.gray)
                            Spacer()
                            Text(meal.typeOfMeal).font(.caption2).bold().foregroundColor(.orange)
                        }
                        Text(meal.ingredient).font(.headline).foregroundColor(.white)
                        HStack {
                            Text("\(String(format: "%.1f", meal.grams))g").font(.subheadline).foregroundColor(.gray)
                            Spacer()
                            Text("\(String(format: "%.1f", meal.nrOfKcalMeal)) Kcal").font(.subheadline).bold().foregroundColor(.cyan)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color(hex: "#1E1E1E"))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Istoric Alimentație")
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { loadMeals() }
    }
    
    private func loadMeals() {
        Task {
            do {
                let fetchedMeals = try await APIService.shared.getAllMeals(email: clientEmail)
                // Sortăm descrescător după dată (cele mai recente primele)
                meals = fetchedMeals.sorted(by: { $0.dayOfMeal > $1.dayOfMeal })
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Nu s-au putut prelua mesele."
            }
        }
    }
}

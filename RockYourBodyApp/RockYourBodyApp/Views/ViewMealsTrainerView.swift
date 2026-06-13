import SwiftUI

struct ViewMealsTrainerView: View {
    let clientEmail: String
    let clientName: String
    
    @State private var meals: [MealOverviewItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading client meals...")
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red).padding()
            } else if meals.isEmpty {
                Text("This client has no saved meals.").foregroundColor(.gray)
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(meals, id: \.idMeal) { meal in
                        ZStack(alignment: .leading) {
                            NavigationLink(destination: AddMealView(
                                clientEmail: clientEmail,
                                clientName: clientName,
                                mealId: meal.idMeal
                            )) {
                                EmptyView()
                            }
                            .opacity(0)
                            
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
                        }
                        .listRowBackground(Color(hex: "#1E1E1E"))
                    }
                    .onDelete(perform: deleteMeal)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Meals: \(clientName)")
        .navigationBarTitleDisplayMode(.inline) // Acest modificator pune titlul pe același rând cu butonul nativ de Back
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { loadMeals() }
    }
    
    private func loadMeals() {
        Task {
            do {
                let fetchedMeals = try await APIService.shared.getAllMeals(email: clientEmail)
                meals = fetchedMeals.sorted(by: { $0.dayOfMeal > $1.dayOfMeal })
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Failed to load meals."
            }
        }
    }
    
    private func deleteMeal(at offsets: IndexSet) {
        offsets.forEach { index in
            let mealId = meals[index].idMeal
            Task {
                do {
                    try await APIService.shared.deleteMeal(idMeal: mealId)
                    meals.remove(at: index)
                } catch {
                    print("Failed to delete meal")
                }
            }
        }
    }
}

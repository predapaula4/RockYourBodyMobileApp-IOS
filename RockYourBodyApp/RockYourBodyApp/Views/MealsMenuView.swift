import SwiftUI

struct MealsMenuView: View {
    let clientEmail: String
    
    @State private var dailyMeals: [MealOverviewItem] = []
    @State private var selectedDate = Date()
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .padding()
                .background(Color(hex: "#1E1E1E"))
                .cornerRadius(16)
                .padding()
                .onChange(of: selectedDate) { _ in loadDailyMeals() }

            if isLoading {
                ProgressView().padding()
            } else if dailyMeals.isEmpty {
                Text("No meals logged for this day.").foregroundColor(.gray).padding()
            } else {
                List(dailyMeals, id: \.idMeal) { meal in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.typeOfMeal).font(.headline).foregroundColor(.orange)
                        Text("\(meal.ingredient) - \(Int(meal.grams))g").foregroundColor(.white)
                        Text("\(Int(meal.nrOfKcalMeal)) Kcal").font(.caption).foregroundColor(.cyan)
                    }
                    .listRowBackground(Color(hex: "#1E1E1E"))
                }
                .listStyle(.insetGrouped)
            }
            Spacer()
            
            NavigationLink(destination: MealIdeasView()) {
                Text("View Meal Ideas & Recipes")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.black)
                    .cornerRadius(12)
            }
            .padding()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Diet Plan")
        .onAppear { loadDailyMeals() }
    }

    private func loadDailyMeals() {
        isLoading = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: selectedDate)
        
        Task {
            do {
                // 1. Apelăm getAllMeals exact așa cum faci pe Android
                let allMeals = try await APIService.shared.getAllMeals(email: clientEmail)
                
                // 2. Filtrăm datele local pe baza datei selectate
                // (Presupunem că `dayOfMeal` este String, cum e în Kotlin)
                dailyMeals = allMeals.filter { meal in
                    // Căutăm prefixul datei (ex: "2026-06-13")
                    return meal.dayOfMeal.hasPrefix(dateStr)
                }
                
                isLoading = false
            } catch {
                // 3. CRITIC: Afișăm eroarea în consolă!
                // Astfel, dacă ai erori de decodare (ex: lipsește o variabilă din model), Xcode îți va spune exact unde e problema.
                print("❌ Eroare la descărcarea/decodarea meselor: \(error)")
                isLoading = false
            }
        }
    }
}

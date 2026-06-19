import SwiftUI

struct OxygenSaturationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    @State private var oxygenValue: Double = 0.0
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea() // Același fundal închis la culoare
            
            VStack(spacing: 0) {
                // Header-ul comun cu butonul de "Back"
                CustomHeader(title: "Oxygen History", dismiss: dismiss)
                
                // Calendarul orizontal refolosibil
                HorizontalCalendarView(selectedDate: $selectedDate, themeColor: Color(hex: "#FF8000")) { date in
                    loadOxygenData(for: date)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Titlul dinamic exact ca la StepsChartView
                        Text(Calendar.current.isDateInToday(selectedDate) ? "Oxygen Today" : "Oxygen: \(formatDate(selectedDate))")
                            .font(.title2).bold().foregroundColor(.white).padding(.top, 24)
                        
                        // Indicatorul Circular de Progres
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 16)
                                .frame(width: 220, height: 220)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(min(oxygenValue / 100.0, 1.0)))
                                .stroke(statusColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .frame(width: 220, height: 220)
                                .rotationEffect(Angle(degrees: -90))
                                .animation(.easeInOut, value: oxygenValue)
                            
                            VStack {
                                Text("\(Int(oxygenValue))")
                                    .font(.system(size: 50, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text("%")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Status Text
                        Text(statusText)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                            .padding(.top, 10)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadOxygenData(for: selectedDate)
        }
        .alert(item: Binding(
            get: { errorMessage != nil ? IdentifiableError(message: errorMessage!) : nil },
            set: { errorMessage = $0?.message }
        )) { error in
            Alert(title: Text("Eroare"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }
    
    // MARK: - Logica de Business / UI Helpers
    
    private func loadOxygenData(for date: Date) {
        Task {
            do {
                // Folosim instanța partajată HealthKitManager la fel ca în restul paginilor
                let value = try await HealthKitManager.shared.fetchOxygenSaturation(for: date)
                DispatchQueue.main.async {
                    self.oxygenValue = value
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "dd MMM"; return f.string(from: date)
    }
    
    private var statusText: String {
        switch oxygenValue {
        case 95...100: return "Status: Normal"
        case 90..<95: return "Status: Low"
        case 1..<90:  return "Status: Critical"
        default:       return "Status: No data"
        }
    }
    
    private var statusColor: Color {
        switch oxygenValue {
        case 95...100: return .green
        case 90..<95: return .yellow
        case 1..<90:  return .red
        default:       return .gray
        }
    }
}

// Structură ajutătoare pentru afișarea alertelor de eroare
struct IdentifiableError: Identifiable {
    let id = UUID()
    let message: String
}

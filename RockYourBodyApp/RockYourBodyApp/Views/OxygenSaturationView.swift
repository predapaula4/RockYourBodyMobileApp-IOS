import SwiftUI

struct OxygenSaturationView: View {
    @StateObject private var hkManager = HealthKitManager()
    
    @State private var selectedDate = Date()
    @State private var oxygenValue: Double = 0.0
    @State private var days: [CalendarDay] = []
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. Titlu dinamic (Echivalentul tvOxygenDayTitle)
            Text(titleForDate(selectedDate))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            // 2. Calendarul Orizontal (Echivalentul rvCalendarOxygen)
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(days) { day in
                            VStack(spacing: 6) {
                                Text(day.dayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(day.dayNumber)
                                    .font(.body)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(Calendar.current.isDate(day.date, inSameDayAs: selectedDate) ? .orange : .gray)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Calendar.current.isDate(day.date, inSameDayAs: selectedDate) ? Color.orange.opacity(0.1) : Color.clear)
                            )
                            .id(day.date)
                            .onTapGesture {
                                selectedDate = day.date
                                loadOxygenData(for: day.date)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    generatePast15Days()
                    // Auto-scroll la ziua de azi (ultima din listă)
                    if let lastDay = days.last {
                        proxy.scrollTo(lastDay.date, anchor: .trailing)
                    }
                }
            }
            .frame(height: 70)
            
            Spacer()
            
            // 3. Indicatorul Circular de Progres (Echivalentul progressOxygen și tvLatestOxygen)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(oxygenValue / 100.0, 1.0)))
                    .stroke(statusColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut, value: oxygenValue)
                
                VStack {
                    Text("\(Int(oxygenValue))")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
            
            // 4. Status Text (Echivalentul tvOxygenStatus)
            Text(statusText)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(statusColor)
                .padding(.top, 10)
            
            Spacer()
            
            // 5. Butonul de Refresh (Echivalentul btnRefreshOxygen)
            Button(action: {
                loadOxygenData(for: selectedDate)
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Data")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
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
    
    private func generatePast15Days() {
        let calendar = Calendar.current
        var list: [CalendarDay] = []
        for i in (0...14).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                list.append(CalendarDay(date: date))
            }
        }
        self.days = list
    }
    
    private func loadOxygenData(for date: Date) {
        Task {
            do {
                let value = try await hkManager.fetchOxygenSaturation(for: date)
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
    
    private func titleForDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Oxygen Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"
            return "Oxygen: \(formatter.string(from: date))"
        }
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

// Preview pentru Xcode simulator
struct OxygenSaturationView_Previews: PreviewProvider {
    static var previews: some View {
        OxygenSaturationView()
    }
}

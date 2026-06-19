import SwiftUI

struct HydrationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    @State private var waterMl: Int = 0
    @State private var showCustomDialog = false
    @State private var customWaterInput = ""
    
    let targetMl = 2500
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea()
            
            VStack(spacing: 0) {
                CustomHeader(title: "Hydration", dismiss: dismiss)
                
                HorizontalCalendarView(selectedDate: $selectedDate, themeColor: Color(hex: "#00B0FF")) { date in
                    loadData(for: date)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        // ... Același Header ca la Performance, adaptat pentru apă ...
                        ZStack {
                            Circle().stroke(Color(hex: "#00B0FF").opacity(0.2), lineWidth: 16).frame(width: 220, height: 220)
                            Circle()
                                .trim(from: 0.0, to: min(CGFloat(Double(waterMl) / Double(targetMl)), 1.0))
                                .stroke(Color(hex: "#00B0FF"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .frame(width: 220, height: 220)
                                .rotationEffect(Angle(degrees: -90))
                            
                            VStack {
                                Image(systemName: "drop.fill").font(.title).foregroundColor(.cyan)
                                Text("\(waterMl)").font(.system(size: 42, weight: .bold)).foregroundColor(.white)
                                Text("ml / \(targetMl) ml").font(.subheadline).foregroundColor(.gray)
                            }
                        }.padding(.top, 24)
                        
                        // Butoane de adăugare
                        VStack(spacing: 16) {
                            Text("Add Water").font(.headline).foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                WaterButton(amount: 250) { addWater(250) }
                                WaterButton(amount: 330) { addWater(330) }
                                WaterButton(amount: 1000) { addWater(1000) }
                            }.padding(.horizontal)
                            
                            Button(action: { showCustomDialog = true }) {
                                Text("Custom Amount")
                                    .frame(maxWidth: .infinity).padding().background(Color(hex: "#1E1E1E")).foregroundColor(Color(hex: "#00B0FF")).cornerRadius(12)
                            }.padding(.horizontal)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadData(for: selectedDate) }
        .alert("Add Custom Amount (ml)", isPresented: $showCustomDialog) {
            TextField("e.g. 500", text: $customWaterInput).keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("Add") {
                if let val = Int(customWaterInput), val > 0 { addWater(val) }
            }
        }
    }
    
    private func loadData(for date: Date) {
        HealthKitManager.shared.getWaterHistory(for: date) { ml in
            DispatchQueue.main.async { self.waterMl = ml }
        }
    }
    
    private func addWater(_ amount: Int) {
        // Împiedicăm adăugarea de apă în zile din viitor
        guard Calendar.current.isDateInToday(selectedDate) || selectedDate < Date() else { return }
        
        HealthKitManager.shared.addWater(amountMl: amount, for: selectedDate) { success in
            if success {
                // Reîncărcăm datele de pe grafic ca să vedem cum crește progresul
                loadData(for: selectedDate)
                
                // Opțional: Adaugă o vibrație ușoară de succes pentru utilizator
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}

struct WaterButton: View {
    let amount: Int; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: "plus")
                Text("\(amount) ml")
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(Color(hex: "#00B0FF").opacity(0.2))
            .foregroundColor(Color(hex: "#00B0FF")).cornerRadius(12)
        }
    }
}

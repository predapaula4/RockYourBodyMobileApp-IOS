import SwiftUI

struct BloodPressureView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate = Date()
    @State private var sys: Float? = nil
    @State private var dia: Float? = nil
    
    var body: some View {
        ZStack {
            Color(hex: "#121212").ignoresSafeArea()
            VStack(spacing: 0) {
                CustomHeader(title: "Blood Pressure", dismiss: dismiss)
                
                HorizontalCalendarView(selectedDate: $selectedDate, themeColor: Color(hex: "#FF5252")) { date in
                    loadData(for: date)
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        ZStack {
                            Circle().stroke(Color(hex: "#FF5252").opacity(0.2), lineWidth: 16).frame(width: 220, height: 220)
                            
                            VStack {
                                Image(systemName: "heart.text.square.fill").font(.title).foregroundColor(Color(hex: "#FF5252"))
                                Text((sys != nil && dia != nil) ? "\(Int(sys!)) / \(Int(dia!))" : "-- / --")
                                    .font(.system(size: 42, weight: .bold)).foregroundColor(.white)
                                Text("mmHg").font(.subheadline).foregroundColor(.gray)
                            }
                        }.padding(.top, 40)
                        
                        Text(statusText)
                            .font(.headline)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(statusColor.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadData(for: selectedDate) }
    }
    
    private func loadData(for date: Date) {
        HealthKitManager.shared.getBloodPressureHistory(for: date) { s, d in
            DispatchQueue.main.async { self.sys = s; self.dia = d }
        }
    }
    
    private var statusText: String {
        guard let s = sys, let d = dia else { return "No Data Available" }
        if s < 120 && d < 80 { return "Normal" }
        if s >= 120 && s <= 129 && d < 80 { return "Elevated" }
        if s >= 130 || d >= 80 { return "High Blood Pressure" }
        return "Unknown"
    }
    private var statusColor: Color {
        guard let s = sys, let d = dia else { return .gray }
        if s < 120 && d < 80 { return .green }
        if s >= 120 && s <= 129 && d < 80 { return .yellow }
        return .red
    }
}

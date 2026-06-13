import SwiftUI

struct SleepDetailView: View {
    @State private var totalSleepMinutes: Int = 430 // ~7h 10m
    @State private var deepSleepMinutes: Int = 110
    @State private var remSleepMinutes: Int = 90
    @State private var lightSleepMinutes: Int = 230
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "moon.stars.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.indigo)
                .padding(.top, 20)
            
            Text("Analiza Somnului")
                .font(.title2).bold()
                .foregroundColor(.white)
            
            Text("\(totalSleepMinutes / 60)h \(totalSleepMinutes % 60)m")
                .font(.system(size: 45, weight: .heavy))
                .foregroundColor(.cyan)
            
            VStack(spacing: 15) {
                SleepStageRow(title: "Somn Profund (Deep)", minutes: deepSleepMinutes, color: .indigo)
                SleepStageRow(title: "Somn REM", minutes: remSleepMinutes, color: .cyan)
                SleepStageRow(title: "Somn Ușor (Light)", minutes: lightSleepMinutes, color: .blue)
            }
            .padding()
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(15)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Detalii Somn")
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

// Sub-componentă pentru rândurile de somn
struct SleepStageRow: View {
    let title: String
    let minutes: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(title).foregroundColor(.gray)
            Spacer()
            Text("\(minutes / 60)h \(minutes % 60)m")
                .bold()
                .foregroundColor(.white)
        }
    }
}

import SwiftUI

struct CustomHeader: View {
    let title: String
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(.cyan)
            }
            Spacer()
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            // Spacer invizibil pentru a centra perfect titlul
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .opacity(0)
        }
        .padding()
        .background(Color(hex: "#121212")) // Asigură continuitatea culorii de fundal
    }
}

struct DetailCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .padding()
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(16)
    }
}

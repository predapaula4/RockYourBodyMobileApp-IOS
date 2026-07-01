import re

with open('/Users/predapaulamaria/Documents/Facultate/RockYourBodyMobileApp-IOS/RockYourBodyApp/RockYourBodyApp/Views/WearableSyncView.swift', 'r') as f:
    code = f.read()

# 1. Add Binding
code = code.replace(
    'struct WearableSyncView: View {\n    @Environment(\\.dismiss) var dismiss',
    'struct WearableSyncView: View {\n    @Binding var isPresented: Bool\n    @Environment(\\.dismiss) var dismiss'
)

# 2. Add NavigationView and fix Header
header_search = """    var body: some View {
        ZStack {
           Color(hex: "#121212").ignoresSafeArea()
            VStack(spacing: 0) {
                // --- HEADER CUSTOM (Așa rezolvăm săritul ecranului) ---
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            
                        }
                        .foregroundColor(.cyan)
                    }
                    Spacer()
                    Text("Wearable Activity")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    // Placeholder invizibil pentru a centra perfect titlul
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        
                    }
                    .opacity(0)
                }
                .padding()"""

header_replace = """    var body: some View {
        NavigationView {
        ZStack {
           Color(hex: "#121212").ignoresSafeArea()
            VStack(spacing: 0) {
                // --- HEADER CUSTOM (Așa rezolvăm săritul ecranului) ---
                HStack {
                    Button(action: { 
                        withAnimation(.spring()) { isPresented = false }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.down")
                            Text("Close")
                        }
                        .foregroundColor(.cyan)
                    }
                    Spacer()
                    Text("Wearable Activity")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.trailing, 60)
                    Spacer()
                }
                .padding()
                .background(Color(hex: "#1E1E1E").ignoresSafeArea(edges: .top))"""

code = code.replace(header_search, header_replace)

# 3. Add NavigationView closing brace and modifiers
footer_search = """        } // Aici se închide ZStack-ul principal
        .navigationBarTitleDisplayMode(.inline) // FIX: Oprește "strângerea"
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar) // Oprim complet iOS-ul din a anima vreo bară nativă
        .onAppear {"""

footer_replace = """        } // Aici se închide ZStack-ul principal
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline) // FIX: Oprește "strângerea"
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar) // Oprim complet iOS-ul din a anima vreo bară nativă
        } // Aici se închide NavigationView
        .navigationViewStyle(.stack)
        .onAppear {"""

code = code.replace(footer_search, footer_replace)

with open('/Users/predapaulamaria/Documents/Facultate/RockYourBodyMobileApp-IOS/RockYourBodyApp/RockYourBodyApp/Views/WearableSyncView.swift', 'w') as f:
    f.write(code)

print("Fix applied successfully!")

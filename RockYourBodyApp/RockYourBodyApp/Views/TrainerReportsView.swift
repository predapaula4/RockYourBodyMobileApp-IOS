import SwiftUI

struct TrainerReportsView: View {
    let trainerEmail: String
    
    @State private var clients: [TrainerClientItem] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    // Proprietate calculată pentru a filtra lista local
    var filteredClients: [TrainerClientItem] {
        if searchText.isEmpty { return clients }
        return clients.filter {
            $0.firstName.localizedCaseInsensitiveContains(searchText) ||
            $0.lastName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Se încarcă clienții...")
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red).padding()
                    .frame(maxHeight: .infinity)
            } else if clients.isEmpty {
                Text("Nu ai niciun client momentan.").foregroundColor(.gray)
                    .frame(maxHeight: .infinity)
            } else {
                List(filteredClients, id: \.email) { client in
                    
                    // CORECTAT: 'trainerEmail' a fost mutat înaintea lui 'clientName' pentru a respecta structura din ClientReportsListView
                    NavigationLink(destination: ClientReportsListView(
                        clientEmail: client.email,
                        trainerEmail: trainerEmail,
                        clientName: "\(client.firstName) \(client.lastName)"
                    )) {
                        HStack(spacing: 15) {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 45, height: 45)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(client.firstName) \(client.lastName)")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(client.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(hex: "#1E1E1E"))
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Caută client...")
            }
        }
        .navigationTitle("Clienții Mei")
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { loadClients() }
    }
    
    private func loadClients() {
        Task {
            do {
                clients = try await APIService.shared.getTrainerClients(email: trainerEmail, search: nil)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Eroare la preluarea clienților."
            }
        }
    }
}

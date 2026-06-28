import SwiftUI

// ÎNLOCUITOR PENTRU ClientReportsListActivity.kt
struct ClientReportsListView: View {
    @Environment(\.dismiss) var dismiss
    
    let clientEmail: String
    let trainerEmail: String
    let clientName: String
    
    @State private var reportList: [ActivityReportDTO] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading reports...")
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red).padding()
            } else if reportList.isEmpty {
                Text("No reports found for this client.")
                    .foregroundColor(.gray)
                    .frame(maxHeight: .infinity)
            } else {
                List(reportList, id: \.idField) { report in
                    // ZStack ascunde săgeata nativă default ">"
                    ZStack(alignment: .leading) {
                        NavigationLink(destination: ViewReportView(
                            reportId: report.id,
                            reportName: formatTitle(report.fileName)
                        )) {
                            EmptyView()
                        }
                        .opacity(0)
                        
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.red)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatTitle(report.fileName))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Sent at: \(formatDate(report.generatedAt))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.cyan)
                                .font(.title3)
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowBackground(Color(hex: "#1E1E1E"))
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Reports: \(clientName)")
        .navigationBarTitleDisplayMode(.inline)
        // Ascundem butonul de back nativ dublat
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { loadReports() }
    }
    
    private func loadReports() {
        Task {
            do {
                let fetchedReports = try await APIService.shared.getClientReportsForTrainer(clientEmail: clientEmail, trainerEmail: trainerEmail)
                self.reportList = fetchedReports.sorted(by: { $0.generatedAt > $1.generatedAt })
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to load reports."
            }
        }
    }
    
    // Logica de formatare a stringurilor exact cum era pe Android
    private func formatTitle(_ rawName: String) -> String {
        if rawName.contains("_din_") && rawName.contains("_la_") {
            let parts = rawName.components(separatedBy: "_din_")[1].components(separatedBy: ".pdf")[0].components(separatedBy: "_la_")
            if parts.count == 2 { return "Report: \(parts[0]) ➔ \(parts[1])" }
        }
        if rawName.contains("AllTime") { return "Full Report (All-Time)" }
        return "Fitness Activity Report"
    }
    
    private func formatDate(_ rawDate: String) -> String {
        let clean = rawDate.replacingOccurrences(of: "T", with: " ")
        return String(clean.prefix(16))
    }
}

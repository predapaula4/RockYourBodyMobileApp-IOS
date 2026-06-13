import SwiftUI
import PDFKit

// 1. Facem un wrapper peste componenta UIKit (PDFView)
struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}

// 2. View-ul SwiftUI care va randa PDF-ul descărcat
struct ViewReportView: View {
    let reportId: Int64
    let reportName: String
    
    @State private var pdfData: Data? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Se descarcă documentul...")
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red).padding()
            } else if let data = pdfData {
                PDFKitView(data: data)
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationTitle(reportName)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onAppear { loadPDF() }
    }
    
    private func loadPDF() {
        Task {
            do {
                pdfData = try await APIService.shared.viewReport(reportId: reportId)
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = "Nu s-a putut descărca raportul. Posibil format invalid."
            }
        }
    }
}

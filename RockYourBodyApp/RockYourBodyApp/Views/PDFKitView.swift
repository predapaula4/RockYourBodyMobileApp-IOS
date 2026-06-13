import SwiftUI
import PDFKit

// Wrapper peste componenta UIKit (PDFView) pentru randare fluidă Apple
struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true // Zoom automat integrat
        pdfView.displayMode = .singlePageContinuous // Scroll curat
        pdfView.backgroundColor = UIColor(Color(hex: "#121212"))
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.dataRepresentation() != data {
            uiView.document = PDFDocument(data: data)
        }
    }
}

// View-ul propriu-zis de destinație
struct ViewReportView: View {
    @Environment(\.dismiss) var dismiss
    
    let reportId: Int64
    let reportName: String
    
    @State private var pdfData: Data? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Downloading document...")
                    .frame(maxHeight: .infinity)
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxHeight: .infinity)
            } else if let data = pdfData {
                PDFKitView(data: data)
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
        .navigationTitle(reportName)
        .navigationBarTitleDisplayMode(.inline)
        // Setăm butonul nostru elegant de Back fără dubluri
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { loadPDFFromServer() }
    }
    
    private func loadPDFFromServer() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Folosește direct APIService care ia .byteStream() nativ
                let data = try await APIService.shared.viewReport(reportId: reportId)
                
                // Validăm formatul brut înainte de a bloca interfața grafică
                if PDFDocument(data: data) != nil {
                    self.pdfData = data
                } else {
                    self.errorMessage = "Downloaded data is not a valid PDF document."
                }
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to download the report from cloud server."
                print("PDF Download Error: \(error)")
            }
        }
    }
}

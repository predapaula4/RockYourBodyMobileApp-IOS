import SwiftUI

struct BodyMeasuresFormView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    // 1. Am schimbat din String direct în tipul Date
    @State private var measurementDate: Date = Date()
    
    @State private var relRightBiceps = ""
    @State private var relLeftBiceps = ""
    @State private var strRightBiceps = ""
    @State private var strLeftBiceps = ""
    @State private var rightForearm = ""
    @State private var leftForearm = ""
    @State private var chestText = ""
    @State private var hipsText = ""
    @State private var rightThigh = ""
    @State private var leftThigh = ""
    @State private var rightShins = ""
    @State private var leftShins = ""
    
    @State private var isLoading = false
    @State private var statusMessage = ""
    
    var body: some View {
        Form {
            Section(header: Text("Temporal Marker").foregroundColor(.gray)) {
                DatePicker("Date of Entry", selection: $measurementDate, displayedComponents: .date)
                    .datePickerStyle(.compact) // Stilul clasic și elegant din iOS
            }
            
            Section(header: Text("Brachial Metrics (Biceps & Forearms)").foregroundColor(.gray)) {
                HStack(spacing: 20) {
                    MeasureInputView(title: "Relaxed R (cm)", text: $relRightBiceps)
                    MeasureInputView(title: "Relaxed L (cm)", text: $relLeftBiceps)
                }
                HStack(spacing: 20) {
                    MeasureInputView(title: "Strained R (cm)", text: $strRightBiceps)
                    MeasureInputView(title: "Strained L (cm)", text: $strLeftBiceps)
                }
                HStack(spacing: 20) {
                    MeasureInputView(title: "Forearm R (cm)", text: $rightForearm)
                    MeasureInputView(title: "Forearm L (cm)", text: $leftForearm)
                }
            }
            
            Section(header: Text("Torso Geometry").foregroundColor(.gray)) {
                MeasureInputView(title: "Chest Cage (cm)", text: $chestText)
                MeasureInputView(title: "Hips / Gluteus Perimeter (cm)", text: $hipsText)
            }
            
            Section(header: Text("Lower Extremities (Thighs & Shins)").foregroundColor(.gray)) {
                HStack(spacing: 20) {
                    MeasureInputView(title: "Thigh R (cm)", text: $rightThigh)
                    MeasureInputView(title: "Thigh L (cm)", text: $leftThigh)
                }
                HStack(spacing: 20) {
                    MeasureInputView(title: "Shin R (cm)", text: $rightShins)
                    MeasureInputView(title: "Shin L (cm)", text: $leftShins)
                }
            }
            
            Button(action: postBodyMeasuresToCloud) {
                if isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else {
                    Text("Save Muscular Progress metrics")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.cyan)
            .disabled(isLoading || chestText.isEmpty || hipsText.isEmpty)
        }
        .navigationTitle("Add Measurements")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            fetchLatestMeasures()
        }
    }
    
    // MARK: - Extragerea ultimelor date
    private func fetchLatestMeasures() {
        isLoading = true
        Task {
            do {
                let response = try await APIService.shared.getClientBodyMeasures(email: clientEmail)
                
                if !response.dates.isEmpty {
                    if let val = response.relaxedRightBiceps.last, val > 0 { relRightBiceps = format(val) }
                    if let val = response.relaxedLeftBiceps.last, val > 0 { relLeftBiceps = format(val) }
                    if let val = response.strainedRightBiceps.last, val > 0 { strRightBiceps = format(val) }
                    if let val = response.strainedLeftBiceps.last, val > 0 { strLeftBiceps = format(val) }
                    
                    if let val = response.rightForearm.last, val > 0 { rightForearm = format(val) }
                    if let val = response.leftForearm.last, val > 0 { leftForearm = format(val) }
                    
                    if let val = response.chest.last, val > 0 { chestText = format(val) }
                    if let val = response.hips.last, val > 0 { hipsText = format(val) }
                    
                    if let val = response.rightThigh.last, val > 0 { rightThigh = format(val) }
                    if let val = response.leftThigh.last, val > 0 { leftThigh = format(val) }
                    
                    if let val = response.rightShins.last, val > 0 { rightShins = format(val) }
                    if let val = response.leftShins.last, val > 0 { leftShins = format(val) }
                }
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
    
    private func format(_ value: Float) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", value) : String(value)
    }
    
    // MARK: - Salvarea datelor noi
    private func postBodyMeasuresToCloud() {
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: measurementDate)
        
        let request = BodyMeasureSubmitRequest(
                email: clientEmail,
                dayOfMeasure: dateStr,
                relaxedRightBiceps: Float(relRightBiceps) ?? 0.0,
                relaxedLeftBiceps: Float(relLeftBiceps) ?? 0.0,
                strainedRightBiceps: Float(strRightBiceps) ?? 0.0,
                strainedLeftBiceps: Float(strLeftBiceps) ?? 0.0,
                rightForearm: Float(rightForearm) ?? 0.0,
                leftForearm: Float(leftForearm) ?? 0.0,
                chest: Float(chestText) ?? 0.0,
                hips: Float(hipsText) ?? 0.0,
                rightThigh: Float(rightThigh) ?? 0.0,
                leftThigh: Float(leftThigh) ?? 0.0,
                rightShins: Float(rightShins) ?? 0.0,
                leftShins: Float(leftShins) ?? 0.0
            )
        
        Task {
            do {
                try await APIService.shared.submitBodyMeasures(requestData: request)
                isLoading = false
                dismiss()
            } catch {
                isLoading = false
            }
        }
    }
}

// MARK: - Subcomponentă pentru Design Curat
struct MeasureInputView: View {
    let title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            TextField("0.0", text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle()) // Adaugă un contur subtil căsuței
        }
    }
}

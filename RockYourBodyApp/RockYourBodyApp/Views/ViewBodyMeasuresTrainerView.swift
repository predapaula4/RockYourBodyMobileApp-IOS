import SwiftUI
import Charts // Librăria nativă iOS pentru grafice

// Structură necesară pentru ca graficul să știe cum să citească punctele
struct MeasureChartPoint: Identifiable {
    let id = UUID()
    let date: String
    let value: Float
}

struct ViewBodyMeasuresTrainerView: View {
    let clientEmail: String
    let clientName: String
    
    @State private var chartData: BodyMeasuresChartResponse? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    // Stări pentru grafic (ca Spinner-ul din Android)
    @State private var selectedMetric = "Chest"
    let availableMetrics = [
        "Chest", "Hips",
        "Relaxed Right Biceps", "Relaxed Left Biceps",
        "Strained Right Biceps", "Strained Left Biceps",
        "Right Forearm", "Left Forearm",
        "Right Thigh", "Left Thigh",
        "Right Shins", "Left Shins"
    ]
    
    // Datele filtrate pentru a fi trimise către grafic în funcție de ce e selectat
    var chartPoints: [MeasureChartPoint] {
        guard let data = chartData else { return [] }
        let values: [Float]
        
        switch selectedMetric {
        case "Chest": values = data.chest
        case "Hips": values = data.hips
        case "Relaxed Right Biceps": values = data.relaxedRightBiceps
        case "Relaxed Left Biceps": values = data.relaxedLeftBiceps
        case "Strained Right Biceps": values = data.strainedRightBiceps
        case "Strained Left Biceps": values = data.strainedLeftBiceps
        case "Right Forearm": values = data.rightForearm
        case "Left Forearm": values = data.leftForearm
        case "Right Thigh": values = data.rightThigh
        case "Left Thigh": values = data.leftThigh
        case "Right Shins": values = data.rightShins
        case "Left Shins": values = data.leftShins
        default: values = []
        }
        
        var points: [MeasureChartPoint] = []
        for i in 0..<min(data.dates.count, values.count) {
            points.append(MeasureChartPoint(date: data.dates[i], value: values[i]))
        }
        return points
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                Spacer()
                ProgressView("Loading measurements...")
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                Text(error).foregroundColor(.red).padding()
                Spacer()
            } else if let data = chartData, data.dates.isEmpty {
                Spacer()
                Text("This client has no saved measurements.")
                    .foregroundColor(.gray)
                Spacer()
            } else if let data = chartData {
                
                // 1. ZONA GRAFICULUI (CHART)
                VStack(alignment: .leading) {
                    HStack {
                         Text("Measure Evolution (cm)").font(.headline).foregroundColor(.white)
                         Spacer()
                         Picker("Select Metric", selection: $selectedMetric) {
                             ForEach(availableMetrics, id: \.self) { metric in
                                 Text(metric).tag(metric)
                             }
                         }
                         .pickerStyle(.menu)
                         .tint(.orange)
                    }
                    .padding(.bottom, 8)
                   
                    if chartPoints.isEmpty {
                        Text("No data available for this metric").foregroundColor(.gray)
                            .frame(height: 220)
                            .frame(maxWidth: .infinity)
                    } else {
                        Chart(chartPoints) { point in
                            // Linia continuă curbată
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Value (cm)", point.value)
                            )
                            .foregroundStyle(Color.cyan)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .interpolationMethod(.catmullRom) // Face linia curbată
                            
                            // Punctele cu TEXTUL DEASUPRA (cm)
                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Value (cm)", point.value)
                            )
                            .foregroundStyle(Color.orange)
                            .symbolSize(50)
                            .annotation(position: .top, spacing: 4) {
                                Text(String(format: "%.1f cm", point.value))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 220)
                    }
                }
                .padding()
                .background(Color(hex: "#1E1E1E"))
                
                Divider().background(Color.gray.opacity(0.5))
                
                // 2. ZONA LISTEI DETALIATE
                List {
                    ForEach(0..<data.dates.count, id: \.self) { index in
                        DisclosureGroup {
                            VStack(spacing: 8) {
                                MeasureRow(label: "Chest", value: data.chest[index])
                                MeasureRow(label: "Hips", value: data.hips[index])
                                Divider().background(Color.gray.opacity(0.3))
                                MeasureRow(label: "Relaxed Biceps (R/L)", valueStr: "\(data.relaxedRightBiceps[index]) / \(data.relaxedLeftBiceps[index])")
                                MeasureRow(label: "Strained Biceps (R/L)", valueStr: "\(data.strainedRightBiceps[index]) / \(data.strainedLeftBiceps[index])")
                                MeasureRow(label: "Forearms (R/L)", valueStr: "\(data.rightForearm[index]) / \(data.leftForearm[index])")
                                Divider().background(Color.gray.opacity(0.3))
                                MeasureRow(label: "Thighs (R/L)", valueStr: "\(data.rightThigh[index]) / \(data.leftThigh[index])")
                                MeasureRow(label: "Shins (R/L)", valueStr: "\(data.rightShins[index]) / \(data.leftShins[index])")
                            }
                            .padding(.vertical, 8)
                        } label: {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.orange)
                                Text("Date: \(data.dates[index])")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .listRowBackground(Color(hex: "#1E1E1E"))
                        .tint(.cyan)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Measures: \(clientName)")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(hex: "#121212").ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { loadMeasures() }
    }
    
    private func loadMeasures() {
        Task {
            do {
                let response = try await APIService.shared.getClientBodyMeasures(email: clientEmail)
                self.chartData = response
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to load measurements."
            }
        }
    }
}

// Sub-componentă pentru UI curat
struct MeasureRow: View {
    var label: String
    var value: Float? = nil
    var valueStr: String? = nil
    
    var body: some View {
        HStack {
            Text(label).foregroundColor(.gray).font(.subheadline)
            Spacer()
            if let val = value {
                Text(String(format: "%.1f cm", val)).bold().foregroundColor(.cyan)
            } else if let valStr = valueStr {
                Text("\(valStr) cm").bold().foregroundColor(.cyan)
            }
        }
    }
}

import SwiftUI
import Charts

struct MeasurementPoint: Identifiable {
    let id = UUID()
    let index: Int
    let dateLabel: String
    let value: Float
}

struct BodyMeasuresOverviewView: View {
    let clientEmail: String
    
    @State private var selectedIndex = 0
    @State private var points: [MeasurementPoint] = []
    @State private var chartResponse: BodyMeasuresChartResponse? = nil
    @State private var isLoading = true
    
    let measurementOptions = [
        "Relaxed Right Biceps", "Relaxed Left Biceps", "Strained Right Biceps", "Strained Left Biceps",
        "Right Forearm", "Left Forearm", "Chest", "Hips",
        "Right Thigh", "Left Thigh", "Right Shins", "Left Shins"
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Selectorul pentru Metrică
            VStack(alignment: .leading, spacing: 8) {
                Text("Select Parameter")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Picker("Measurement", selection: $selectedIndex) {
                    ForEach(0..<measurementOptions.count, id: \.self) { i in
                        Text(measurementOptions[i]).tag(i)
                    }
                }
                .pickerStyle(.menu)
                .tint(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(hex: "#1E1E1E"))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .onChange(of: selectedIndex) { _ in parseActiveMetrics() }
            
            // Zona Graficului
            VStack {
                if isLoading {
                    ProgressView().frame(height: 280)
                } else if points.isEmpty {
                    Text("No tracking data available for this parameter.")
                        .foregroundColor(.gray)
                        .frame(height: 280)
                } else {
                    Chart {
                        ForEach(points) { p in
                            // Linia principală curbată (fără umbră/AreaMark)
                            LineMark(
                                x: .value("Date", p.dateLabel),
                                y: .value("Size", p.value)
                            )
                            .foregroundStyle(Color.orange)
                            .lineStyle(StrokeStyle(lineWidth: 3))
                            .interpolationMethod(.catmullRom)
                            
                            // Punctele cu TEXTUL DEASUPRA (cm)
                            PointMark(
                                x: .value("Date", p.dateLabel),
                                y: .value("Size", p.value)
                            )
                            .foregroundStyle(Color.orange)
                            .symbolSize(50)
                            .annotation(position: .top, spacing: 4) {
                                Text(String(format: "%.1f cm", p.value))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .frame(height: 280)
                    .padding()
                }
            }
            .background(Color(hex: "#1E1E1E"))
            .cornerRadius(16)
            .padding(.horizontal)
            
            Spacer()
            
            NavigationLink(destination: BodyMeasuresFormView(clientEmail: clientEmail)) {
                Text("Add New Measurement")
                    .font(.headline)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
        }
        .padding(.top, 16)
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Anthropometrial Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadServerMeasures() }
    }
    
    private func loadServerMeasures() {
        Task {
            do {
                let data = try await APIService.shared.getClientBodyMeasures(email: clientEmail)
                chartResponse = data
                parseActiveMetrics()
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
    
    private func parseActiveMetrics() {
        guard let data = chartResponse else { return }
        let valuesList: [Float] = {
            switch selectedIndex {
            case 0: return data.relaxedRightBiceps
            case 1: return data.relaxedLeftBiceps
            case 2: return data.strainedRightBiceps
            case 3: return data.strainedLeftBiceps
            case 4: return data.rightForearm
            case 5: return data.leftForearm
            case 6: return data.chest
            case 7: return data.hips
            case 8: return data.rightThigh
            case 9: return data.leftThigh
            case 10: return data.rightShins
            case 11: return data.leftShins
            default: return []
            }
        }()
        
        points = (0..<valuesList.count).map { i in
            MeasurementPoint(index: i, dateLabel: data.dates[i], value: valuesList[i])
        }
    }
}

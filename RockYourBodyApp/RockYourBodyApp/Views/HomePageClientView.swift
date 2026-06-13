import SwiftUI

struct HomePageClientView: View {
    @State private var clientEmail = UserDefaults.standard.string(forKey: "USER_EMAIL") ?? ""
    @State private var dashboardData: ClientDashboardResponse? = nil
    @State private var isLoading = true
    @State private var trainerEmail: String = ""
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Loading...").padding(.top, 100)
            } else if let data = dashboardData {
                VStack(spacing: 20) {
                    // 1. Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hello, \(data.firstName)!").font(.largeTitle).bold()
                            Text("🔥 Streak: \(data.streak) Days").foregroundColor(.orange)
                        }
                        Spacer()
                        NavigationLink(destination: MyPersonalClientView(clientEmail: clientEmail)) {
                            if let b64 = data.profileImage, let d = Data(base64Encoded: b64), let img = UIImage(data: d) {
                                Image(uiImage: img).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill").resizable().frame(width: 50, height: 50).foregroundColor(.gray)
                            }
                        }
                    }.padding(.horizontal)
                    
                    // 2. Metrice (Grid)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DashboardMetricView(title: "Goal", value: data.goal, icon: "target", color: .cyan)
                        DashboardMetricView(title: "Daily Kcal", value: "\(Int(data.kcal))", icon: "flame.fill", color: .orange)
                        DashboardMetricView(title: "Weight", value: "\(data.weight) kg", icon: "scalemass.fill", color: .purple)
                        DashboardMetricView(title: "BMR", value: "\(Int(data.bmr))", icon: "bolt.heart.fill", color: .green)
                    }.padding(.horizontal)
                    
                    // 3. Wearable Sync
                    NavigationLink(destination: WearableSyncView(clientEmail: clientEmail, trainerEmail: trainerEmail)) {
                        HStack {
                            Image(systemName: "applewatch.radiowaves.left.and.right")
                            Text("Wearable Activity & Sync")
                        }
                        .font(.headline).foregroundColor(.black).frame(maxWidth: .infinity).padding().background(Color.cyan).cornerRadius(12)
                    }.padding(.horizontal)
                    
                    // 4. Meniu (Butoanele care nu mergeau)
                    VStack(spacing: 12) {
                        NavigationLink(destination: BadgesView(clientEmail: clientEmail)) { ClientMenuButton(title: "Achievements & Badges", icon: "medal.fill", iconColor: .yellow) }
                        NavigationLink(destination: BodyMeasuresFormView(clientEmail: clientEmail)) { ClientMenuButton(title: "Add Body Measures", icon: "ruler.fill") }
                        NavigationLink(destination: ClientImcView(clientEmail: clientEmail)) { ClientMenuButton(title: "BMI & TDEE", icon: "plus.forwardslash.minus") }
                        NavigationLink(destination: BodyMeasuresOverviewView(clientEmail: clientEmail)) { ClientMenuButton(title: "Body Measures Overview", icon: "chart.line.uptrend.xyaxis") }
                        NavigationLink(destination: ClientProgressOverviewView(clientEmail: clientEmail)) { ClientMenuButton(title: "Progress Gallery & Weight", icon: "photo.on.rectangle.angled") }
                        NavigationLink(destination: MealsMenuView(clientEmail: clientEmail)) { ClientMenuButton(title: "Diet Plan & Meals", icon: "fork.knife") }
                        NavigationLink(destination: ExerciseMenuView(clientEmail: clientEmail)) { ClientMenuButton(title: "Workout Plan", icon: "dumbbell.fill") }
                        NavigationLink(destination: ChatOptionsView(clientEmail: clientEmail)) { ClientMenuButton(title: "Contact Trainer", icon: "message.fill") }
                    }.padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
    // Mutăm modificatorii aici, pe ScrollView
        .navigationBarBackButtonHidden(true) // Opțional, ca să nu se întoarcă la ecranul de Login accidental prin swipe
        .onAppear {
            loadDashboard()
            triggerUpdateAccess()
            NotificationManager.shared.requestPermission()
            NotificationManager.shared.scheduleWaterReminder()
        }
    }
    
    private func loadDashboard() {
        Task {
            if let data = try? await APIService.shared.getClientDashboard(email: clientEmail) {
                self.dashboardData = data
                self.trainerEmail = (try? await APIService.shared.getTrainerEmail(clientEmail: clientEmail)) ?? ""
                self.isLoading = false
            }
        }
    }
    
    private func triggerUpdateAccess() {
        let request = UpdateAccessRequest(email: clientEmail, userType: "client")
        Task { try? await APIService.shared.updateLastAccess(requestData: request) }
    }
}

struct ClientMenuButton: View {
    let title: String
    let icon: String
    var iconColor: Color = .cyan
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
    }
}
struct DashboardMetricView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.headline)
                .bold()
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(hex: "#1E1E1E"))
        .cornerRadius(12)
    }
}

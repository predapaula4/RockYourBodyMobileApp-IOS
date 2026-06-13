import SwiftUI

struct BadgesView: View {
    @Environment(\.dismiss) var dismiss
    let clientEmail: String
    
    @State private var badgesList: [BadgeResponse] = []
    @State private var currentStreakText = "Current Streak: -- Days"
    @State private var isLoading = true
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    Text(currentStreakText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.top)
                    
                    if isLoading {
                        ProgressView().padding(.top, 40)
                    } else if badgesList.isEmpty {
                        Text("No achievements unlocked yet. Finish planned logs inside calendar view to award certificates.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(badgesList, id: \.code) { badge in
                                VStack(spacing: 8) {
                                    AsyncImage(url: URL(string: badge.imageUrl)) { img in
                                        img.resizable().scaledToFit()
                                    } placeholder: {
                                        Circle().fill(Color(hex: "#29292c"))
                                    }
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    
                                    Text(badge.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(badge.description)
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, minHeight: 160)
                                .background(Color(hex: "#1E1E1E"))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
            }
            Spacer()
        }
        .background(Color(hex: "#121212").ignoresSafeArea())
        .navigationTitle("Achievements & Badges")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadAchievements() }
    }
    
    private func loadAchievements() {
        Task {
            do {
                let dashboardData = try await APIService.shared.getClientDashboard(email: clientEmail)
                badgesList = dashboardData.badges
                currentStreakText = "Current Streak: 🔥 \(dashboardData.streak) Days"
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
}

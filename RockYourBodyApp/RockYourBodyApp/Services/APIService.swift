import Foundation

class APIService {
    // Singleton de acces global
    static let shared = APIService()
    private init() {}
    
    // URL-ul de bază al serverului tău
    private let baseURL = "https://rockyourbody-1.onrender.com"
    
    // MARK: - Helper Core pentru construirea cererilor HTTP standard
    private func createRequest(endpoint: String, method: String, queryParams: [String: String?]? = nil, body: Data? = nil) throws -> URLRequest {
        guard var components = URLComponents(string: baseURL + endpoint) else {
            throw URLError(.badURL)
        }
        
        if let queryParams = queryParams {
            components.queryItems = queryParams.compactMap { key, value in
                guard let value = value else { return nil }
                return URLQueryItem(name: key, value: value)
            }
        }
        
        guard let url = components.url else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Interceptor JWT
        if let token = UserDefaults.standard.string(forKey: "JWT_TOKEN") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        return request
    }
    
    private func createMultipartRequest(endpoint: String, email: String, folder: String, fileData: Data) throws -> URLRequest {
        guard let url = URL(string: baseURL + endpoint) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Adăugăm un prefix standard pentru boundary
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "JWT_TOKEN") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        
        // Parametrul: email (Adăugăm Content-Type exact ca în Android)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"email\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/plain; charset=utf-8\r\n\r\n".data(using: .utf8)!)
        body.append("\(email)\r\n".data(using: .utf8)!)
        
        // Parametrul: folder
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"folder\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: text/plain; charset=utf-8\r\n\r\n".data(using: .utf8)!)
        body.append("\(folder)\r\n".data(using: .utf8)!)
        
        // Parametrul: file (Imaginea)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Lăsăm URLSession să gestioneze automat Content-Length pentru a evita conflictele (Am comentat linia problematica)
        // request.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
        
        return request
    }

    // =========================================================================
    // MARK: - 1. AUTHENTICATION & ACCESS
    // =========================================================================
    func loginMobile(requestData: LoginRequest) async throws -> MobileAuthResponse {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/auth/login", method: "POST", body: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(MobileAuthResponse.self, from: data)
    }

    func googleLoginMobile(payload: [String: String]) async throws -> [String: Any] {
            let body = try JSONSerialization.data(withJSONObject: payload)
            let request = try createRequest(endpoint: "/api/mobile/auth/google", method: "POST", body: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // --- NOU: LOGARE PENTRU DEBUGGING ---
            if let httpResponse = response as? HTTPURLResponse, let responseString = String(data: data, encoding: .utf8) {
                print("🚀 [LOG GOOGLE AUTH] Status Server: \(httpResponse.statusCode)")
                print("📦 [LOG GOOGLE AUTH] Răspuns Brut: \(responseString)")
            }
            // ------------------------------------
            
            return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        }

    func updateLastAccess(requestData: UpdateAccessRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/auth/update-access", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func saveFcmToken(email: String, token: String) async throws {
        let params = ["email": email, "token": token]
        let request = try createRequest(endpoint: "/api/mobile/auth/save-token", method: "POST", queryParams: params)
        let _ = try await URLSession.shared.data(for: request)
    }

    func registerClient(client: ClientFormDto) async throws {
        let body = try JSONEncoder().encode(client)
        let request = try createRequest(endpoint: "/api/mobile/auth/register/client", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func registerTrainer(trainer: TrainerFormDto) async throws {
        let body = try JSONEncoder().encode(trainer)
        let request = try createRequest(endpoint: "/api/mobile/auth/register/trainer", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    // =========================================================================
    // MARK: - 2. TRAINER MANAGEMENT
    // =========================================================================
    func getTrainerClients(email: String, search: String? = nil) async throws -> [TrainerClientItem] {
        let params = ["email": email, "search": search]
        let request = try createRequest(endpoint: "/api/mobile/trainer/clients", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([TrainerClientItem].self, from: data)
    }

    func getTrainerProfile(email: String) async throws -> TrainerProfileResponse {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/trainer/profile", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TrainerProfileResponse.self, from: data)
    }

    func deleteTrainer(email: String) async throws {
        let request = try createRequest(endpoint: "/trainer/delete/\(email)", method: "DELETE")
        let _ = try await URLSession.shared.data(for: request)
    }
    
    func updateTrainerProfile(requestData: [String: String]) async throws {
        let body = try JSONSerialization.data(withJSONObject: requestData)
        let request = try createRequest(endpoint: "/api/mobile/trainer/update-profile", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func getTrainerName(email: String) async throws -> TrainerNameResponse {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/trainer-name", method: "POST", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TrainerNameResponse.self, from: data)
    }

    func sendCustomNotification(clientEmail: String, message: String) async throws {
        let params = ["clientEmail": clientEmail, "notificationMessage": message]
        let request = try createRequest(endpoint: "/api/mobile/trainer/send-custom-notification", method: "POST", queryParams: params)
        let _ = try await URLSession.shared.data(for: request)
    }

    func getAllSystemBadges() async throws -> [BadgeResponse] {
        let request = try createRequest(endpoint: "/api/mobile/trainer/all-badges", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([BadgeResponse].self, from: data)
    }

    func awardBadgeFromMobile(clientEmail: String, badgeCode: String) async throws {
        let params = ["clientEmail": clientEmail, "badgeCode": badgeCode]
        let request = try createRequest(endpoint: "/api/mobile/trainer/award-badge", method: "POST", queryParams: params)
        let _ = try await URLSession.shared.data(for: request)
    }

    // =========================================================================
    // MARK: - 3. CLIENT PROFILE & DASHBOARD
    // =========================================================================
    func getClientProfile(email: String) async throws -> ClientResponse {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/client/profile", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ClientResponse.self, from: data)
    }

    func getClientProfileDetails(email: String) async throws -> ClientProfileResponse {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/client/profile", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ClientProfileResponse.self, from: data)
    }

    func updateClientProfile(requestData: [String: Any]) async throws {
            // Folosim JSONSerialization pentru a transforma dicționarul în date JSON
            let body = try JSONSerialization.data(withJSONObject: requestData)
            
            // Creăm și trimitem request-ul (asigură-te că endpoint-ul este cel corect)
            let request = try createRequest(endpoint: "/api/client/update-profile", method: "POST", body: body)
            let _ = try await URLSession.shared.data(for: request)
        }

    func getClientDashboard(email: String) async throws -> ClientDashboardResponse {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/client/dashboard", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ClientDashboardResponse.self, from: data)
    }

    func submitGoalMobile(requestData: GoalSubmitRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/client/addGoal", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func getClientImcData(email: String) async throws -> ClientImcDataResponse {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/client/imcData", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ClientImcDataResponse.self, from: data)
    }

    func submitClientProgress(requestData: ClientProgressSubmitRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/client/submitProgress", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func submitBodyMeasures(requestData: BodyMeasureSubmitRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/client/submitBodyMeasures", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func getClientBodyMeasures(email: String) async throws -> BodyMeasuresChartResponse {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/client/bodyMeasuresOverview", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(BodyMeasuresChartResponse.self, from: data)
    }

    func getClientProgressOverview(email: String) async throws -> ClientProgressChartResponse {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/client/progressOverview", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ClientProgressChartResponse.self, from: data)
    }

    func getMyTrainerEmail(clientEmail: String) async throws -> [String: String] {
        let params = ["clientEmail": clientEmail]
        let request = try createRequest(endpoint: "/api/mobile/client/trainer-email", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: String] ?? [:]
    }

    // NOTĂ: Ambele endpoint-uri de getTrainerEmail din Android le-am unit aici pentru consistență
    func getTrainerEmail(clientEmail: String) async throws -> String {
        let params = ["clientEmail": clientEmail]
        let request = try createRequest(endpoint: "/api/mobile/client/get-trainer-email", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return String(data: data, encoding: .utf8) ?? ""
    }

    // =========================================================================
    // MARK: - 4. NUTRITION & MEALS
    // =========================================================================
    func calculateCalories(requestData: IngredientCaloriesRequest) async throws -> [String: Double] {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/calculateCalories", method: "POST", body: body)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Double] ?? [:]
    }

    func getRemainingKcal(email: String, date: String) async throws -> [String: Float] {
        let params = ["email": email, "date": date]
        let request = try createRequest(endpoint: "/api/mobile/client/remainingCalories", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONSerialization.jsonObject(with: data) as? [String: Float] ?? [:]
    }

    func submitMeal(requestData: MealSubmitRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/client/submitMeal", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }
    
    func syncMealData(requestData: MealSubmitRequest) async throws { // Alias cerut de un ecran anterior
        try await submitMeal(requestData: requestData)
    }

    func getMealDetails(idMeal: Int) async throws -> MealOverviewItem {
        let request = try createRequest(endpoint: "/api/mobile/meal/\(idMeal)", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(MealOverviewItem.self, from: data)
    }

    func updateMeal(idMeal: Int, requestData: MealSubmitRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/meal/\(idMeal)", method: "PUT", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func getAllMeals(email: String) async throws -> [MealOverviewItem] {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/client/allMeals", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([MealOverviewItem].self, from: data)
    }

    func deleteMeal(idMeal: Int) async throws {
        let request = try createRequest(endpoint: "/api/mobile/meal/\(idMeal)", method: "DELETE")
        let _ = try await URLSession.shared.data(for: request)
    }

    func getMealIdeas() async throws -> [MealIdeas] {
        let request = try createRequest(endpoint: "/api/mobile/meal-ideas", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([MealIdeas].self, from: data)
    }

    // =========================================================================
    // MARK: - 5. EXERCISES & ACTIVITIES
    // =========================================================================
    func getActivitiesForDay(email: String, date: String) async throws -> DailyActivitiesResponse {
        let params = ["email": email, "date": date]
        let request = try createRequest(endpoint: "/api/mobile/client/activitiesForDay", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(DailyActivitiesResponse.self, from: data)
    }

    func submitExercise(requestData: ExerciseSubmitRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/trainer/submitExercise", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func getAllExercises(email: String) async throws -> [ExerciseOverviewItem] {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/trainer/allExercises", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ExerciseOverviewItem].self, from: data)
    }

    func deleteExercise(id: Int) async throws {
        let request = try createRequest(endpoint: "/api/mobile/trainer/exercise/\(id)", method: "DELETE")
        let _ = try await URLSession.shared.data(for: request)
    }

    func getExerciseDetails(id: Int) async throws -> ExerciseOverviewItem {
        let request = try createRequest(endpoint: "/api/mobile/trainer/exercise/\(id)", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(ExerciseOverviewItem.self, from: data)
    }

    func updateExercise(id: Int, requestData: ExerciseSubmitRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/trainer/exercise/\(id)", method: "PUT", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func getExerciseExamples(category: String) async throws -> [ExerciseExampleItem] {
        let params = ["category": category]
        let request = try createRequest(endpoint: "/api/mobile/exercises", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ExerciseExampleItem].self, from: data)
    }

    func getClientExercises(email: String) async throws -> [ExerciseOverviewItem] {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/mobile/client/exercises", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ExerciseOverviewItem].self, from: data)
    }

    // =========================================================================
    // MARK: - 6. CHAT
    // =========================================================================
    func getChatMessages(trainerEmail: String, clientEmail: String) async throws -> [ChatMessageOverviewItem] {
        let params = ["trainerEmail": trainerEmail, "clientEmail": clientEmail]
        let request = try createRequest(endpoint: "/api/mobile/chat/messages", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ChatMessageOverviewItem].self, from: data)
    }

    func sendMessageMobile(requestData: ChatMessageRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/chat/send", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    // =========================================================================
    // MARK: - 7. PROGRESS PHOTOS
    // =========================================================================
    func uploadProgressPhoto(email: String, folder: String, imageData: Data) async throws -> UploadResponse {
            // Folosim funcția ta creată deja la începutul fișierului, care se ocupă de Multipart și Token
            let request = try createMultipartRequest(
                endpoint: "/api/progress/upload",
                email: email,
                folder: folder,
                fileData: imageData
            )
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            
            return try JSONDecoder().decode(UploadResponse.self, from: data)
        }

    func getPhotosByFolder(email: String, folder: String) async throws -> [ProgressPhotoResponse] {
        let params = ["email": email, "folder": folder]
        let request = try createRequest(endpoint: "/api/progress/all", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ProgressPhotoResponse].self, from: data)
    }

    func deletePhoto(photoUrl: String) async throws {
        let params = ["photoUrl": photoUrl]
        let request = try createRequest(endpoint: "/api/progress/photo", method: "DELETE", queryParams: params)
        let _ = try await URLSession.shared.data(for: request)
    }

    func deleteFolder(email: String, folder: String) async throws {
        let params = ["email": email, "folder": folder]
        let request = try createRequest(endpoint: "/api/progress/folder", method: "DELETE", queryParams: params)
        let _ = try await URLSession.shared.data(for: request)
    }

    func batchDeletePhotos(photoUrls: [String]) async throws {
        let body = try JSONEncoder().encode(photoUrls)
        let request = try createRequest(endpoint: "/api/progress/batch", method: "DELETE", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func getClientFolders(email: String) async throws -> [String] {
        let params = ["email": email]
        let request = try createRequest(endpoint: "/api/progress/folders", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([String].self, from: data)
    }

    // =========================================================================
    // MARK: - 8. WEARABLES & REPORTS
    // =========================================================================
    func syncWearableData(requestData: DailyActivitySyncRequest) async throws {
        let body = try JSONEncoder().encode(requestData)
        let request = try createRequest(endpoint: "/api/mobile/client/sync-wearable", method: "POST", body: body)
        let _ = try await URLSession.shared.data(for: request)
    }

    func exportToTrainer(clientEmail: String, trainerEmail: String, startDate: String?, endDate: String?) async throws {
        let params = ["clientEmail": clientEmail, "trainerEmail": trainerEmail, "startDate": startDate, "endDate": endDate]
        let request = try createRequest(endpoint: "/api/mobile/client/export-to-trainer", method: "POST", queryParams: params)
        let _ = try await URLSession.shared.data(for: request)
    }

    func viewReport(reportId: Int64) async throws -> Data {
        // Observație: Returnează "Data" brută deoarece backend-ul returnează un fișier de tip PDF (Streaming)
        let request = try createRequest(endpoint: "/api/mobile/client/view-report/\(reportId)", method: "GET")
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }

    func getClientReportsForTrainer(clientEmail: String, trainerEmail: String) async throws -> [ActivityReportDTO] {
        let params = ["clientEmail": clientEmail, "trainerEmail": trainerEmail]
        let request = try createRequest(endpoint: "/api/mobile/client/trainer/client-reports", method: "GET", queryParams: params)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ActivityReportDTO].self, from: data)
    }
    
    func askAIBot(message: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/mobile/chat/ask") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Dacă endpoint-ul e securizat, adaugă token-ul JWT aici:
        if let token = UserDefaults.standard.string(forKey: "USER_TOKEN") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let chatReq = AIChatRequest(message: message)
        request.httpBody = try JSONEncoder().encode(chatReq)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let chatRes = try JSONDecoder().decode(AIChatResponse.self, from: data)
        return chatRes.reply
    }
}
struct AIChatRequest: Codable {
    let message: String
}

struct AIChatResponse: Codable {
    let reply: String
}

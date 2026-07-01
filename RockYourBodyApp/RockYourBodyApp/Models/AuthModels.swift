import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct MobileAuthResponse: Codable {
    let userType: String // "client" sau "trainer"
    let user: GenericUserResponse // Folosim structura comună pentru a evita erorile de parsare
}


struct GenericUserResponse: Codable {
    let idClient: Int? = nil
    let idTrainer: Int? = nil
    let firstName: String
    let lastName: String
    let email: String
}
struct ClientResponse: Codable {
    let idClient: Int
    let firstName: String
    let lastName: String
    let email: String
    let weight: Float
    let height: Float
    let numberOfKcal: Float
    let goalType: String?
    let goalValue: Int?
    let gender: String?
    let fullPhoneNumber: String?
    let age: String?
}

// Model pentru răspunsul combinat de activități : Codable {Mese + Exerciții}
struct DailyActivitiesResponse: Codable {
    let meals: [MealOverviewItem]
    let exercises: [ExerciseOverviewItem]
}

struct TrainerClientItem: Codable {
    let email: String
    let firstName: String
    let lastName: String
    let phoneNumber: String
    let profileImageBase64: String? = nil
}


// Request pentru salvarea sau actualizarea unei mese
struct MealSubmitRequest: Codable {
    let clientEmail: String
    let dayOfMeal: String
    let typeOfMeal: String
    let ingredient: String
    let grams: Double
}

// Request pentru calculatorul de calorii
struct IngredientCaloriesRequest: Codable {
    let ingredient: String
    let grams: Double
}

// Model pentru afișarea detaliilor unei mese : Codable {folosit la editare sau liste}
struct MealOverviewItem: Codable {
    let idMeal: Int
    var id: Int { idMeal}
    let dayOfMeal: String
    let typeOfMeal: String
    let ingredient: String
    let grams: Float
    let nrOfKcalMeal: Float
    let formattedDayOfMeal: String

}

// În AuthModels.kt sau într-un fișier nou de modele
struct ExerciseSubmitRequest: Codable {
    let clientEmail: String
    let dayOfExercise: String
    let bodyPart: String
    let exerciseName: String
    let numberOfSeries: Int
    let numberOfRepsPerSerie: String
    let weightForEachRep: String
}

struct ExerciseOverviewItem: Codable {
    let idExercise: Int
    var id: Int { idExercise}
    let dayOfExercise: String
    let bodyPart: String
    let exerciseName: String
    let numberOfSeries: Int
    let numberOfRepsPerSerie: String
    let weightForEachRep: String
    let formattedDayOfExercise: String? = nil
}

struct BodyMeasuresOverviewItem: Codable {
    let idBodyMeasures: Int
    let dayOfMeasure: String
    let relaxedRightBiceps: Float
    let relaxedLeftBiceps: Float
    let strainedRightBiceps: Float
    let strainedLeftBiceps: Float
    let rightForearm: Float
    let leftForearm: Float
    let chest: Float
    let hips: Float
    let rightThigh: Float
    let leftThigh: Float
    let rightShins: Float
    let leftShins: Float
    var formattedDayOfBodyMeasureOverview: String? = nil
}

struct ChatMessageOverviewItem: Codable {
    let idMessage: Int
    var id: Int { idMessage }
    let senderId: String
    let senderName: String
    let receiverId: String
    let receiverName: String
    let message: String
    let formattedTimestamp: String
    let senderEmail: String?
}

// Folosit pentru trimiterea mesajelor noi
struct ChatMessageRequest: Codable {
    let senderEmail: String
    let receiverEmail: String
    let content: String
}

struct TrainerProfileResponse: Codable {
    let idTrainer: Int
    let firstName: String
    let lastName: String
    let email: String
    let age: String? // Data nașterii sub formă de String yyyy-MM-dd
    let cod: String
    let gender: String?
    let phoneNumber: String?
    let fullPhoneNumber: String?
    let profileImageBase64: String?
}
struct ClientFormDto: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let weight: Float
    let height: Float
    let age: String // "yyyy-MM-dd"
    let gender: String // 'M' sau 'F'
    let activity: String
    let codTrainer: String
    let phoneNumber: String
    let fullPhoneNumber: String
    let countryCode: String
    let profileImage: Data?
}

struct TrainerFormDto: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    let age: String // "yyyy-MM-dd"
    let gender: String
    let cod: String?
    let phoneNumber: String
    let fullPhoneNumber: String
    let countryCode: String
    let profileImage: Data?
}

struct ClientDashboardResponse: Codable, Equatable {
    let firstName: String
    let kcal: Float
    let weight: Float
    let bmr: Float
    let goal: String
    let profileImage: String?
    let streak: Int
    let badges: [BadgeResponse]
}
struct BadgeResponse: Codable, Equatable {
    let code: String
    let name: String
    let description: String
    let imageUrl: String
}
struct MealIdeas: Codable {
    let name: String
    let imageUrlMeal: String // URL-ul imaginii : Codable {ex: /bootstrap/images/...}
    let numberOfServing: Int
    let preparationTime: String
    let cooking: String
    let preparationInstructions: String
    let ingredients: String
    let calories: Double
    let protein: Double
    let carbohydrate: Double
    let fats: Double
}
struct GoalSubmitRequest: Codable {
    let email: String
    let goalType: String
    let goalValue: Int
}
struct ClientImcDataResponse: Codable {
    let weight: Float
    let height: Float
    let age: Int
    let gender: String
    let activity: String?
    let lastDate: String?
}

struct ClientProgressSubmitRequest: Codable {
    let email: String
    let date: String
    let weight: Float
    let height: Float
    let bmi: Float
    let bmr: Float
    let tdee: Float
}
struct BodyMeasureSubmitRequest: Codable {
    let email: String
    let dayOfMeasure: String
    let relaxedRightBiceps: Float
    let relaxedLeftBiceps: Float
    let strainedRightBiceps: Float
    let strainedLeftBiceps: Float
    let rightForearm: Float
    let leftForearm: Float
    let chest: Float
    let hips: Float
    let rightThigh: Float
    let leftThigh: Float
    let rightShins: Float
    let leftShins: Float
}
struct BodyMeasuresChartResponse: Codable {
    let dates: [String]
    let relaxedRightBiceps: [Float]
    let relaxedLeftBiceps: [Float]
    let strainedRightBiceps: [Float]
    let strainedLeftBiceps: [Float]
    let rightForearm: [Float]
    let leftForearm: [Float]
    let chest: [Float]
    let hips: [Float]
    let rightThigh: [Float]
    let leftThigh: [Float]
    let rightShins: [Float]
    let leftShins: [Float]
}
struct ClientProgressChartResponse: Codable {
    let dates: [String]
    let weights: [Float]
}

struct ExerciseExampleItem: Codable {
    let name: String
    let imageUrlStartPosition: String?
    let imageUrlIntermediatePosition1: String?
    let imageUrlIntermediatePosition2: String?
    let imageUrlMuscularGroup: String?
    let description: String?
}
struct DailyActivitySyncRequest: Codable {
    let email: String
    let date: String
    let steps: Int
    let caloriesBurned: Float
    let activeCalories: Float?
    let distanceMeters: Float
    let floorsClimbed: Double
    let sleepMinutes: Int
    let avgHeartRate: Float
    let maxHeartRate: Float
    let minHeartRate: Float
    let latestHeartRate: Float
    let restingHeartRate: Float
    let waterMl: Int
    let bodyFat: Float?
    let weight: Float?
    let oxygenSaturation: Float?
    let systolicBP: Float?
    let diastolicBP: Float?
    let activityIntensityMinutes: Int?
    let avgSpeed: Float?
    let avgCadence: Float?
    let vo2Max: Float?
    let elevationGained: Float?
    let wheelchairPushes: Int?
    let powerWatts: Float?
    let exerciseSessionsCount: Int?
    var totalSleepMinutes: Int?
    var deepSleepMin: Int?
    var remSleepMin: Int?
    var lightSleepMin: Int?
    var awakeMin: Int?
}

struct ClientProfileResponse: Codable {
    let firstName: String
    let lastName: String
    let gender: String
    let email: String
    let fullPhoneNumber: String?
    let phoneNumber: String
    let weight: Float
    let height: Float
    let birthDate: String?
    let activityLevel: String?
    let trainerCode: String?
    let goalDescription: String?
    let goal: String?
    let profileImageBase64: String?
    let age: Int
}

struct TrainerNameResponse: Codable {
    let fullName: String
}
struct ProgressPhotoResponse: Codable {
    var idField: Int64 { id }
    let id: Int64
    let clientEmail: String
    let folderName: String
    let photoUrl: String
}

struct UploadResponse: Codable {let url: String}

struct ActivityReportDTO: Codable {
    var idField: Int64 { id }
    let id: Int64
    let clientEmail: String
    let fileName: String
    let generatedAt: String
}
struct UpdateAccessRequest: Codable {
    let email: String
    let userType: String
}

import SwiftUI

extension Color {
    init(hex: String) {
        // 1. Curățăm string-ul de caractere nedorite (ex: "#")
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        // 2. Transformăm string-ul hexazecimal direct în număr (Metoda modernă)
        let int = UInt64(cleanHex, radix: 16) ?? 0
        
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0) // Default fallback (Negru)
        }
        
        // 3. Inițializăm culoarea
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

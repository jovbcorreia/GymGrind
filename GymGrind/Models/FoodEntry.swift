import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case lunch     = "Lunch"
    case dinner    = "Dinner"
    case snack     = "Snack"

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch:     return "sun.max.fill"
        case .dinner:    return "moon.stars.fill"
        case .snack:     return "bolt.fill"
        }
    }
}

@Model
final class FoodEntry {
    var id: UUID
    var date: Date
    var meal: String          // MealType.rawValue
    var name: String
    var calories: Int
    var proteinG: Double
    var carbsG: Double
    var fatG: Double

    var mealType: MealType {
        MealType(rawValue: meal) ?? .snack
    }

    init(date: Date = Date(), meal: MealType, name: String,
         calories: Int, proteinG: Double, carbsG: Double, fatG: Double) {
        self.id       = UUID()
        self.date     = date
        self.meal     = meal.rawValue
        self.name     = name
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG   = carbsG
        self.fatG     = fatG
    }
}

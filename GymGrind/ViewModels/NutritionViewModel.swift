import Foundation
import SwiftUI
import SwiftData

@Observable
class NutritionViewModel {
    func todayEntries(from allEntries: [FoodEntry]) -> [FoodEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.date) }
    }

    func entries(for meal: MealType, from allEntries: [FoodEntry]) -> [FoodEntry] {
        todayEntries(from: allEntries).filter { $0.mealType == meal }
    }

    func totalCalories(from entries: [FoodEntry]) -> Int {
        entries.reduce(0) { $0 + $1.calories }
    }

    func totalProtein(from entries: [FoodEntry]) -> Double {
        entries.reduce(0) { $0 + $1.proteinG }
    }

    func totalCarbs(from entries: [FoodEntry]) -> Double {
        entries.reduce(0) { $0 + $1.carbsG }
    }

    func totalFat(from entries: [FoodEntry]) -> Double {
        entries.reduce(0) { $0 + $1.fatG }
    }

    func weeklyAverageCalories(from allEntries: [FoodEntry]) -> Int {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = allEntries.filter { $0.date >= sevenDaysAgo }

        guard !recent.isEmpty else { return 0 }

        // Group by day
        let grouped = Dictionary(grouping: recent) {
            calendar.startOfDay(for: $0.date)
        }
        let dailyTotals = grouped.values.map { $0.reduce(0) { $0 + $1.calories } }
        return dailyTotals.reduce(0, +) / max(dailyTotals.count, 1)
    }

    func weeklyAverageMacros(from allEntries: [FoodEntry]) -> (protein: Double, carbs: Double, fat: Double) {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recent = allEntries.filter { $0.date >= sevenDaysAgo }

        guard !recent.isEmpty else { return (0, 0, 0) }

        let grouped = Dictionary(grouping: recent) {
            calendar.startOfDay(for: $0.date)
        }
        let count = Double(grouped.count)
        let totalP = recent.reduce(0.0) { $0 + $1.proteinG } / count
        let totalC = recent.reduce(0.0) { $0 + $1.carbsG }   / count
        let totalF = recent.reduce(0.0) { $0 + $1.fatG }     / count
        return (totalP, totalC, totalF)
    }
}

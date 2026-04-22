import Foundation
import SwiftUI

enum WeightUnit: String, CaseIterable {
    case kg  = "kg"
    case lbs = "lbs"

    func convert(_ value: Double, to target: WeightUnit) -> Double {
        guard self != target else { return value }
        return target == .lbs ? value * 2.20462 : value / 2.20462
    }
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("userName")        var userName: String     = ""
    @AppStorage("weightUnit")      var weightUnitRaw: String = WeightUnit.kg.rawValue
    @AppStorage("calorieGoal")     var calorieGoal: Int     = 2500
    @AppStorage("proteinGoal")     var proteinGoal: Double  = 150
    @AppStorage("carbsGoal")       var carbsGoal: Double    = 300
    @AppStorage("fatGoal")         var fatGoal: Double      = 80
    @AppStorage("onboardingDone")  var onboardingDone: Bool = false
    @AppStorage("waterGoalML")     var waterGoalML: Int     = 2500
    @AppStorage("waterLoggedML")   var waterLoggedML: Int   = 0
    @AppStorage("lastWaterDate")   var lastWaterDateStr: String = ""

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitRaw) ?? .kg }
        set { weightUnitRaw = newValue.rawValue }
    }

    func displayWeight(_ kg: Double) -> String {
        let val = weightUnit == .kg ? kg : kg * 2.20462
        return String(format: "%.1f", val)
    }

    func displayWeightShort(_ kg: Double) -> String {
        let val = weightUnit == .kg ? kg : kg * 2.20462
        return val == val.rounded() ? String(Int(val)) : String(format: "%.1f", val)
    }

    func inputToKg(_ value: Double) -> Double {
        weightUnit == .kg ? value : value / 2.20462
    }

    func kgToInput(_ kg: Double) -> Double {
        weightUnit == .kg ? kg : kg * 2.20462
    }

    // Reset water log daily
    func checkAndResetWater() {
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        if lastWaterDateStr != today {
            waterLoggedML = 0
            lastWaterDateStr = today
        }
    }
}

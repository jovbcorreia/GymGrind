import Foundation
import SwiftData

@Model
final class SetEntry {
    var id: UUID
    var setNumber: Int
    var weightKg: Double
    var reps: Int
    var completed: Bool
    var isPR: Bool

    init(setNumber: Int, weightKg: Double = 0, reps: Int = 0) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.completed = false
        self.isPR = false
    }
}

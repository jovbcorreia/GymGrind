import Foundation
import SwiftData

@Model
final class ExerciseEntry {
    var id: UUID
    var exerciseName: String
    var order: Int
    @Relationship(deleteRule: .cascade) var sets: [SetEntry]

    init(exerciseName: String, order: Int = 0) {
        self.id = UUID()
        self.exerciseName = exerciseName
        self.order = order
        self.sets = []
    }

    var maxWeightKg: Double {
        sets.max(by: { $0.weightKg < $1.weightKg })?.weightKg ?? 0
    }

    var totalVolume: Double {
        sets.reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
    }

    var completedSets: [SetEntry] {
        sets.filter(\.completed).sorted(by: { $0.setNumber < $1.setNumber })
    }
}

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var name: String
    var durationMinutes: Int
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseEntry]

    init(name: String = "Workout", date: Date = Date(), durationMinutes: Int = 0) {
        self.id = UUID()
        self.name = name
        self.date = date
        self.durationMinutes = durationMinutes
        self.exercises = []
    }

    var totalVolumeKg: Double {
        exercises.flatMap(\.sets).reduce(0) { $0 + ($1.weightKg * Double($1.reps)) }
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var formattedDuration: String {
        if durationMinutes < 60 {
            return "\(durationMinutes)m"
        }
        let h = durationMinutes / 60
        let m = durationMinutes % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

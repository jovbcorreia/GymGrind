import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID
    var name: String
    var exerciseNames: [String]
    var createdAt: Date

    init(name: String, exerciseNames: [String] = []) {
        self.id            = UUID()
        self.name          = name
        self.exerciseNames = exerciseNames
        self.createdAt     = Date()
    }
}

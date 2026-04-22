import Foundation
import SwiftData

@Model
final class BodyMetric {
    var id: UUID
    var date: Date
    var weightKg: Double
    var bodyFatPercent: Double?

    init(date: Date = Date(), weightKg: Double, bodyFatPercent: Double? = nil) {
        self.id              = UUID()
        self.date            = date
        self.weightKg        = weightKg
        self.bodyFatPercent  = bodyFatPercent
    }
}

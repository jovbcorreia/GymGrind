import Foundation
import SwiftData

// MARK: - Supabase API Models (Codable, espelham as tabelas SQL)

struct SBWorkoutSession: Codable {
    var id: String?
    var user_id: String?
    var name: String
    var date: Date
    var duration_minutes: Int
}

struct SBExerciseEntry: Codable {
    var id: String?
    var session_id: String
    var exercise_name: String
    var order_index: Int
}

struct SBSetEntry: Codable {
    var id: String?
    var exercise_id: String
    var set_number: Int
    var weight_kg: Double
    var reps: Int
    var completed: Bool
    var is_pr: Bool
}

struct SBFoodEntry: Codable {
    var id: String?
    var user_id: String?
    var date: Date
    var meal: String
    var name: String
    var calories: Int
    var protein_g: Double
    var carbs_g: Double
    var fat_g: Double
}

struct SBBodyMetric: Codable {
    var id: String?
    var user_id: String?
    var date: Date
    var weight_kg: Double
    var body_fat_percent: Double?
}

struct SBWorkoutTemplate: Codable {
    var id: String?
    var user_id: String?
    var name: String
    var exercise_names: [String]
}

struct SBProfile: Codable {
    var id: String?
    var username: String?
    var weight_unit: String?
    var calorie_goal: Int?
    var protein_goal: Double?
    var carbs_goal: Double?
    var fat_goal: Double?
    var water_goal_ml: Int?
}

// MARK: - SupabaseService
// Sincroniza dados SwiftData ↔ Supabase
// A app usa SwiftData localmente (offline-first)
// Supabase é o backup na cloud

@Observable
class SupabaseService {
    static let shared = SupabaseService()
    private let client = SupabaseClient.shared
    private let auth   = SupabaseAuth.shared

    var isSyncing = false
    var lastSyncError: String? = nil

    // MARK: - Workout Sessions

    func uploadSession(_ session: WorkoutSession) async {
        guard let userId = auth.userId else { return }
        do {
            var sb = SBWorkoutSession(
                id: session.id.uuidString,
                user_id: userId,
                name: session.name,
                date: session.date,
                duration_minutes: session.durationMinutes
            )
            let _ : SBWorkoutSession = try await client.insert(table: "workout_sessions", body: sb)

            // Upload exercises
            for exercise in session.exercises {
                try await uploadExercise(exercise, sessionId: session.id.uuidString)
            }
        } catch {
            lastSyncError = error.localizedDescription
            print("⚠️ Supabase upload session error: \(error)")
        }
    }

    func uploadExercise(_ exercise: ExerciseEntry, sessionId: String) async throws {
        let sb = SBExerciseEntry(
            id: exercise.id.uuidString,
            session_id: sessionId,
            exercise_name: exercise.exerciseName,
            order_index: exercise.order
        )
        let _ : SBExerciseEntry = try await client.insert(table: "exercise_entries", body: sb)

        for set in exercise.sets {
            try await uploadSet(set, exerciseId: exercise.id.uuidString)
        }
    }

    func uploadSet(_ set: SetEntry, exerciseId: String) async throws {
        let sb = SBSetEntry(
            id: set.id.uuidString,
            exercise_id: exerciseId,
            set_number: set.setNumber,
            weight_kg: set.weightKg,
            reps: set.reps,
            completed: set.completed,
            is_pr: set.isPR
        )
        let _ : SBSetEntry = try await client.insert(table: "set_entries", body: sb)
    }

    func deleteSession(id: UUID) async {
        do {
            try await client.delete(table: "workout_sessions", id: id.uuidString)
        } catch {
            print("⚠️ Supabase delete session error: \(error)")
        }
    }

    // MARK: - Food Entries

    func uploadFoodEntry(_ entry: FoodEntry) async {
        guard let userId = auth.userId else { return }
        do {
            let sb = SBFoodEntry(
                id: entry.id.uuidString,
                user_id: userId,
                date: entry.date,
                meal: entry.meal,
                name: entry.name,
                calories: entry.calories,
                protein_g: entry.proteinG,
                carbs_g: entry.carbsG,
                fat_g: entry.fatG
            )
            let _ : SBFoodEntry = try await client.insert(table: "food_entries", body: sb)
        } catch {
            print("⚠️ Supabase upload food error: \(error)")
        }
    }

    func deleteFoodEntry(id: UUID) async {
        do {
            try await client.delete(table: "food_entries", id: id.uuidString)
        } catch {
            print("⚠️ Supabase delete food error: \(error)")
        }
    }

    // MARK: - Body Metrics

    func uploadBodyMetric(_ metric: BodyMetric) async {
        guard let userId = auth.userId else { return }
        do {
            let sb = SBBodyMetric(
                id: metric.id.uuidString,
                user_id: userId,
                date: metric.date,
                weight_kg: metric.weightKg,
                body_fat_percent: metric.bodyFatPercent
            )
            let _ : SBBodyMetric = try await client.insert(table: "body_metrics", body: sb)
        } catch {
            print("⚠️ Supabase upload metric error: \(error)")
        }
    }

    // MARK: - Templates

    func uploadTemplate(_ template: WorkoutTemplate) async {
        guard let userId = auth.userId else { return }
        do {
            let sb = SBWorkoutTemplate(
                id: template.id.uuidString,
                user_id: userId,
                name: template.name,
                exercise_names: template.exerciseNames
            )
            let _ : SBWorkoutTemplate = try await client.insert(table: "workout_templates", body: sb)
        } catch {
            print("⚠️ Supabase upload template error: \(error)")
        }
    }

    func deleteTemplate(id: UUID) async {
        do {
            try await client.delete(table: "workout_templates", id: id.uuidString)
        } catch {
            print("⚠️ Supabase delete template error: \(error)")
        }
    }

    // MARK: - Pull (download cloud → SwiftData)
    // Usado quando o user faz login num novo dispositivo

    func pullAllData(into context: ModelContext) async {
        guard auth.isLoggedIn else { return }
        isSyncing = true
        defer { isSyncing = false }

        do {
            // Pull food entries
            let foods: [SBFoodEntry] = try await client.get(
                table: "food_entries",
                query: "order=date.desc"
            )
            for f in foods {
                guard let idStr = f.id, let id = UUID(uuidString: idStr) else { continue }
                let existing = try? context.fetch(FetchDescriptor<FoodEntry>(
                    predicate: #Predicate { $0.id == id }
                )).first
                if existing == nil {
                    let entry = FoodEntry(
                        date: f.date,
                        meal: MealType(rawValue: f.meal) ?? .snack,
                        name: f.name,
                        calories: f.calories,
                        proteinG: f.protein_g,
                        carbsG: f.carbs_g,
                        fatG: f.fat_g
                    )
                    entry.id = id
                    context.insert(entry)
                }
            }

            // Pull body metrics
            let metrics: [SBBodyMetric] = try await client.get(
                table: "body_metrics",
                query: "order=date.desc"
            )
            for m in metrics {
                guard let idStr = m.id, let id = UUID(uuidString: idStr) else { continue }
                let existing = try? context.fetch(FetchDescriptor<BodyMetric>(
                    predicate: #Predicate { $0.id == id }
                )).first
                if existing == nil {
                    let metric = BodyMetric(date: m.date, weightKg: m.weight_kg, bodyFatPercent: m.body_fat_percent)
                    metric.id = id
                    context.insert(metric)
                }
            }

            // Pull templates
            let templates: [SBWorkoutTemplate] = try await client.get(table: "workout_templates")
            for t in templates {
                guard let idStr = t.id, let id = UUID(uuidString: idStr) else { continue }
                let existing = try? context.fetch(FetchDescriptor<WorkoutTemplate>(
                    predicate: #Predicate { $0.id == id }
                )).first
                if existing == nil {
                    let template = WorkoutTemplate(name: t.name, exerciseNames: t.exercise_names)
                    template.id = id
                    context.insert(template)
                }
            }

            print("✅ Supabase pull completed")
        } catch {
            lastSyncError = error.localizedDescription
            print("⚠️ Supabase pull error: \(error)")
        }
    }

    // MARK: - Profile sync

    func syncProfile(settings: AppSettings) async {
        guard let userId = auth.userId else { return }
        do {
            let profiles: [SBProfile] = try await client.get(
                table: "profiles",
                query: "id=eq.\(userId)"
            )
            if let profile = profiles.first {
                if let unit = profile.weight_unit  { settings.weightUnitRaw = unit }
                if let cal  = profile.calorie_goal  { settings.calorieGoal  = cal  }
                if let p    = profile.protein_goal  { settings.proteinGoal  = p    }
                if let c    = profile.carbs_goal    { settings.carbsGoal    = c    }
                if let f    = profile.fat_goal      { settings.fatGoal      = f    }
                if let w    = profile.water_goal_ml { settings.waterGoalML  = w    }
                if let name = profile.username, !name.isEmpty { settings.userName = name }
            }
        } catch {
            print("⚠️ Supabase profile sync error: \(error)")
        }
    }

    func uploadProfile(settings: AppSettings) async {
        guard let userId = auth.userId else { return }
        do {
            let sb = SBProfile(
                id: userId,
                username: settings.userName,
                weight_unit: settings.weightUnitRaw,
                calorie_goal: settings.calorieGoal,
                protein_goal: settings.proteinGoal,
                carbs_goal: settings.carbsGoal,
                fat_goal: settings.fatGoal,
                water_goal_ml: settings.waterGoalML
            )
            try await client.update(table: "profiles", id: userId, body: sb)
        } catch {
            print("⚠️ Supabase upload profile error: \(error)")
        }
    }
}

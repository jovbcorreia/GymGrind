import Foundation
import SwiftUI
import SwiftData

@Observable
class WorkoutViewModel {
    var activeSession: WorkoutSession?
    var isSessionActive: Bool = false
    var sessionStartTime: Date = Date()
    var elapsedSeconds: Int = 0
    var timer: Timer?

    // PR detection
    var newPRExercise: String? = nil
    var showPRBanner: Bool = false

    // Rest timer
    var restTimerSeconds: Int = 0
    var restTimerActive: Bool = false
    var restTimer: Timer?
    var selectedRestDuration: Int = 90

    // Exercise library (common exercises)
    let exerciseLibrary: [String] = [
        "Bench Press", "Incline Bench Press", "Decline Bench Press",
        "Push Up", "Cable Fly", "Dumbbell Fly", "Chest Dip",
        "Squat", "Leg Press", "Romanian Deadlift", "Leg Curl",
        "Leg Extension", "Hip Thrust", "Lunges", "Calf Raise",
        "Deadlift", "Barbell Row", "Pull Up", "Lat Pulldown",
        "Seated Row", "Face Pull", "Shrug", "Good Morning",
        "Overhead Press", "Arnold Press", "Lateral Raise", "Front Raise",
        "Upright Row", "Cable Lateral",
        "Bicep Curl", "Hammer Curl", "Preacher Curl", "Incline Curl",
        "Tricep Dip", "Skull Crusher", "Tricep Pushdown", "Overhead Extension",
        "Plank", "Ab Wheel", "Crunch", "Leg Raise", "Russian Twist",
        "Cable Crunch", "Hanging Leg Raise"
    ]

    func startSession(name: String, context: ModelContext, template: WorkoutTemplate? = nil) {
        let session = WorkoutSession(name: name)
        context.insert(session)

        if let template = template {
            for (i, exerciseName) in template.exerciseNames.enumerated() {
                let entry = ExerciseEntry(exerciseName: exerciseName, order: i)
                context.insert(entry)
                session.exercises.append(entry)
            }
        }

        activeSession = session
        isSessionActive = true
        sessionStartTime = Date()
        elapsedSeconds = 0
        startTimer()
    }

    func endSession(context: ModelContext) {
        guard let session = activeSession else { return }
        session.durationMinutes = elapsedSeconds / 60
        stopTimer()
        stopRestTimer()
        // Upload to Supabase in background
        let sessionCopy = session
        Task { await SupabaseService.shared.uploadSession(sessionCopy) }
        activeSession = nil
        isSessionActive = false
    }

    func discardSession(context: ModelContext) {
        guard let session = activeSession else { return }
        context.delete(session)
        stopTimer()
        stopRestTimer()
        activeSession = nil
        isSessionActive = false
    }

    func addExercise(name: String, to session: WorkoutSession, context: ModelContext) {
        let order = session.exercises.count
        let entry = ExerciseEntry(exerciseName: name, order: order)
        context.insert(entry)
        session.exercises.append(entry)
    }

    func addSet(to exercise: ExerciseEntry, weight: Double, reps: Int, context: ModelContext) {
        let setNum = exercise.sets.count + 1
        let set = SetEntry(setNumber: setNum, weightKg: weight, reps: reps)
        context.insert(set)
        exercise.sets.append(set)
    }

    func removeExercise(_ exercise: ExerciseEntry, from session: WorkoutSession, context: ModelContext) {
        session.exercises.removeAll { $0.id == exercise.id }
        context.delete(exercise)
    }

    func removeSet(_ set: SetEntry, from exercise: ExerciseEntry, context: ModelContext) {
        exercise.sets.removeAll { $0.id == set.id }
        context.delete(set)
        // Renumber
        for (i, s) in exercise.sets.sorted(by: { $0.setNumber < $1.setNumber }).enumerated() {
            s.setNumber = i + 1
        }
    }

    // Check PR against historical sessions
    func checkPR(exercise: ExerciseEntry, weight: Double, reps: Int,
                 allSessions: [WorkoutSession]) -> Bool {
        let historicMax = allSessions
            .filter { $0.id != activeSession?.id }
            .flatMap(\.exercises)
            .filter { $0.exerciseName == exercise.exerciseName }
            .flatMap(\.sets)
            .map(\.weightKg)
            .max() ?? 0

        return weight > historicMax
    }

    func triggerPR(exerciseName: String) {
        newPRExercise = exerciseName
        withAnimation { showPRBanner = true }
        HapticFeedback.notification(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.showPRBanner = false }
        }
    }

    // Previous session data for suggestions
    func previousSet(for exerciseName: String, setNumber: Int,
                     allSessions: [WorkoutSession]) -> SetEntry? {
        let previous = allSessions
            .filter { $0.id != activeSession?.id }
            .sorted(by: { $0.date > $1.date })
            .first?
            .exercises
            .first { $0.exerciseName == exerciseName }?
            .sets
            .first { $0.setNumber == setNumber }
        return previous
    }

    // MARK: - Timers
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func startRestTimer(seconds: Int = 90) {
        stopRestTimer()
        restTimerSeconds = seconds
        restTimerActive = true
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.restTimerSeconds > 0 {
                self.restTimerSeconds -= 1
            } else {
                self.stopRestTimer()
                HapticFeedback.notification(.success)
            }
        }
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        restTimerActive = false
        restTimerSeconds = 0
    }

    var elapsedFormatted: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    var restTimerFormatted: String {
        String(format: "%d:%02d", restTimerSeconds / 60, restTimerSeconds % 60)
    }
}

import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(WorkoutViewModel.self) private var workoutVM
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]

    let session: WorkoutSession

    @State private var showExerciseSearch = false
    @State private var showFinishAlert = false
    @State private var showDiscardAlert = false
    @State private var showRestTimer = false
    @State private var showSaveTemplate = false
    @State private var templateName = ""

    var sortedExercises: [ExerciseEntry] {
        session.exercises.sorted(by: { $0.order < $1.order })
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.ggBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                workoutHeader

                ScrollView {
                    VStack(spacing: 16) {
                        // Rest timer (if active)
                        if workoutVM.restTimerActive {
                            RestTimerBanner()
                        }

                        // PR Banner
                        if workoutVM.showPRBanner, let exercise = workoutVM.newPRExercise {
                            PRBannerView(exerciseName: exercise)
                        }

                        // Exercises
                        ForEach(sortedExercises) { exercise in
                            ExerciseCard(
                                exercise: exercise,
                                allSessions: allSessions,
                                onAddSet: { weight, reps in
                                    addSet(to: exercise, weight: weight, reps: reps)
                                },
                                onRemove: {
                                    workoutVM.removeExercise(exercise, from: session, context: context)
                                }
                            )
                        }

                        // Add Exercise
                        Button {
                            showExerciseSearch = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("ADD EXERCISE")
                                    .tracking(1)
                            }
                            .font(.ggSubtitle)
                            .foregroundColor(.ggAccent)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.ggSurface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                    .foregroundColor(Color.ggAccent.opacity(0.3))
                            )
                        }

                        // Finish / Discard
                        VStack(spacing: 10) {
                            Button("FINISH WORKOUT") {
                                showFinishAlert = true
                            }
                            .buttonStyle(GGButtonStyle(color: .ggNeon))

                            Button("Discard Workout") {
                                showDiscardAlert = true
                            }
                            .font(.ggCaption)
                            .foregroundColor(.ggDanger)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
        }
        .sheet(isPresented: $showExerciseSearch) {
            ExerciseSearchView { exerciseName in
                workoutVM.addExercise(name: exerciseName, to: session, context: context)
                showExerciseSearch = false
            }
        }
        .sheet(isPresented: $showSaveTemplate) {
            saveTemplateSheet
        }
        .alert("Finish Workout?", isPresented: $showFinishAlert) {
            Button("Save Session", role: .none) {
                workoutVM.endSession(context: context)
            }
            Button("Save as Template") {
                showFinishAlert = false
                showSaveTemplate = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your workout will be saved to history.")
        }
        .alert("Discard Workout?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                workoutVM.discardSession(context: context)
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("All progress in this session will be lost.")
        }
    }

    var workoutHeader: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name.uppercased())
                        .font(.ggHeadline)
                        .foregroundColor(.ggText)
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(workoutVM.elapsedFormatted)
                            .font(.ggMonoSmall)
                    }
                    .foregroundColor(.ggAccent)
                }
                Spacer()

                // Rest timer toggle
                Button {
                    if workoutVM.restTimerActive {
                        workoutVM.stopRestTimer()
                    } else {
                        workoutVM.startRestTimer(seconds: workoutVM.selectedRestDuration)
                    }
                } label: {
                    Image(systemName: workoutVM.restTimerActive ? "timer.circle.fill" : "timer")
                        .font(.title2)
                        .foregroundColor(workoutVM.restTimerActive ? .ggAccent : .ggTextSecondary)
                }
                .padding(.trailing, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Rectangle().fill(Color.ggBorder).frame(height: 1)
        }
        .background(Color.ggBackground)
    }

    func addSet(to exercise: ExerciseEntry, weight: Double, reps: Int) {
        workoutVM.addSet(to: exercise, weight: weight, reps: reps, context: context)

        // Check PR
        let previousMax = allSessions
            .filter { $0.id != session.id }
            .flatMap(\.exercises)
            .filter { $0.exerciseName == exercise.exerciseName }
            .flatMap(\.sets)
            .map(\.weightKg)
            .max() ?? 0

        if weight > previousMax && previousMax > 0 {
            exercise.sets.last?.isPR = true
            workoutVM.triggerPR(exerciseName: exercise.exerciseName)
        }

        // Auto start rest timer
        workoutVM.startRestTimer(seconds: workoutVM.selectedRestDuration)
    }

    var saveTemplateSheet: some View {
        NavigationStack {
            ZStack {
                Color.ggBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("SAVE AS TEMPLATE")
                        .font(.ggHeadline)
                        .foregroundColor(.ggText)

                    TextField("Template name", text: $templateName)
                        .font(.ggTitle)
                        .foregroundColor(.ggText)
                        .padding(16)
                        .background(Color.ggSurface)
                        .cornerRadius(10)

                    Button("SAVE TEMPLATE") {
                        let name = templateName.isEmpty ? session.name : templateName
                        let exerciseNames = sortedExercises.map(\.exerciseName)
                        let template = WorkoutTemplate(name: name, exerciseNames: exerciseNames)
                        context.insert(template)
                        workoutVM.endSession(context: context)
                        showSaveTemplate = false
                    }
                    .buttonStyle(GGButtonStyle())

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        workoutVM.endSession(context: context)
                        showSaveTemplate = false
                    }
                    .foregroundColor(.ggAccent)
                }
            }
            .toolbarBackground(Color.ggBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Exercise Card
struct ExerciseCard: View {
    @Environment(WorkoutViewModel.self) private var workoutVM
    @EnvironmentObject private var settings: AppSettings

    let exercise: ExerciseEntry
    let allSessions: [WorkoutSession]
    let onAddSet: (Double, Int) -> Void
    let onRemove: () -> Void

    @State private var weightStr: String = ""
    @State private var repsStr: String = ""
    @State private var showRemoveAlert = false

    var previousEntry: ExerciseEntry? {
        allSessions
            .filter { !Calendar.current.isDateInToday($0.date) }
            .sorted(by: { $0.date > $1.date })
            .first?
            .exercises
            .first { $0.exerciseName == exercise.exerciseName }
    }

    var sortedSets: [SetEntry] {
        exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })
    }

    var body: some View {
        VStack(spacing: 0) {
            // Exercise header
            HStack {
                Text(exercise.exerciseName.uppercased())
                    .font(.ggSubtitle)
                    .foregroundColor(.ggText)
                Spacer()
                Button {
                    showRemoveAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.ggTextSecondary)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Previous session hint
            if let prev = previousEntry, let lastSet = prev.completedSets.first {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                    Text("Last: \(settings.displayWeightShort(lastSet.weightKg))\(settings.weightUnit.rawValue) × \(lastSet.reps)")
                        .font(.ggCaption)
                }
                .foregroundColor(.ggTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Logged sets
            if !sortedSets.isEmpty {
                VStack(spacing: 0) {
                    // Header row
                    HStack {
                        Text("SET").frame(width: 36, alignment: .leading)
                        Spacer()
                        Text("WEIGHT").frame(width: 80, alignment: .center)
                        Spacer()
                        Text("REPS").frame(width: 50, alignment: .center)
                        Spacer()
                        Text("").frame(width: 20)
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.ggTextSecondary)
                    .tracking(0.5)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                    ForEach(sortedSets) { set in
                        SetRow(set: set, settings: settings)
                    }
                }
            }

            // Add set input row
            HStack(spacing: 12) {
                // Weight
                HStack(spacing: 4) {
                    TextField(suggestedWeight, text: $weightStr)
                        .font(.ggMono)
                        .foregroundColor(.ggText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 70)
                    Text(settings.weightUnit.rawValue)
                        .font(.ggCaption)
                        .foregroundColor(.ggTextSecondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.ggSurface2)
                .cornerRadius(8)

                Text("×")
                    .foregroundColor(.ggTextSecondary)

                // Reps
                HStack(spacing: 4) {
                    TextField(suggestedReps, text: $repsStr)
                        .font(.ggMono)
                        .foregroundColor(.ggText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 50)
                    Text("reps")
                        .font(.ggCaption)
                        .foregroundColor(.ggTextSecondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.ggSurface2)
                .cornerRadius(8)

                Spacer()

                Button {
                    logSet()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.ggNeon)
                }
                .disabled(weightStr.isEmpty && repsStr.isEmpty)
                .opacity((weightStr.isEmpty && repsStr.isEmpty) ? 0.4 : 1)
            }
            .padding(16)
        }
        .background(Color.ggSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ggBorder, lineWidth: 1))
        .alert("Remove Exercise?", isPresented: $showRemoveAlert) {
            Button("Remove", role: .destructive) { onRemove() }
            Button("Cancel", role: .cancel) {}
        }
    }

    var suggestedWeight: String {
        if let prev = previousEntry, let lastSet = prev.completedSets.last {
            let suggested = settings.kgToInput(lastSet.weightKg) + (settings.weightUnit == .kg ? 2.5 : 5)
            return String(format: "%.1f", suggested)
        }
        return "0"
    }

    var suggestedReps: String {
        if let prev = previousEntry, let lastSet = prev.completedSets.last {
            return "\(lastSet.reps)"
        }
        return "0"
    }

    func logSet() {
        let w = Double(weightStr) ?? (Double(suggestedWeight) ?? 0)
        let r = Int(repsStr) ?? (Int(suggestedReps) ?? 0)
        let wKg = settings.inputToKg(w)
        onAddSet(wKg, r)
        weightStr = ""
        repsStr = ""
        HapticFeedback.impact(.medium)
    }
}

// MARK: - Set Row
struct SetRow: View {
    let set: SetEntry
    let settings: AppSettings

    var body: some View {
        HStack {
            Text("\(set.setNumber)")
                .font(.ggMonoSmall)
                .foregroundColor(.ggTextSecondary)
                .frame(width: 36, alignment: .leading)
            Spacer()
            HStack(spacing: 2) {
                Text(settings.displayWeightShort(set.weightKg))
                    .font(.ggMonoSmall)
                    .foregroundColor(.ggText)
                if set.isPR {
                    Text(" PR")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.ggNeon)
                }
            }
            .frame(width: 80, alignment: .center)
            Spacer()
            Text("\(set.reps)")
                .font(.ggMonoSmall)
                .foregroundColor(.ggText)
                .frame(width: 50, alignment: .center)
            Spacer()
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.ggNeon)
                .frame(width: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(set.isPR ? Color.ggNeon.opacity(0.05) : Color.clear)
    }
}

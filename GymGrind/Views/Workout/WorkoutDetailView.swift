import SwiftUI

struct WorkoutDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    let session: WorkoutSession

    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    var sortedExercises: [ExerciseEntry] {
        session.exercises.sorted(by: { $0.order < $1.order })
    }

    var body: some View {
        ZStack {
            Color.ggBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Summary header card
                    summaryCard

                    // Exercises
                    ForEach(sortedExercises) { exercise in
                        exerciseDetailCard(exercise)
                    }

                    // Delete button
                    Button("Delete Workout") {
                        showDeleteAlert = true
                    }
                    .font(.ggCaption)
                    .foregroundColor(.ggDanger)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(16)
            }
        }
        .navigationTitle(session.name.uppercased())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.ggBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Delete Workout?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.date, style: .date)
                        .font(.ggSubtitle)
                        .foregroundColor(.ggTextSecondary)
                    Text(session.date, style: .time)
                        .font(.ggCaption)
                        .foregroundColor(.ggTextSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.formattedDuration)
                        .font(.ggMonoSmall)
                        .foregroundColor(.ggAccent)
                    Text("duration")
                        .font(.ggCaption)
                        .foregroundColor(.ggTextSecondary)
                }
            }

            Divider().background(Color.ggBorder)

            HStack(spacing: 0) {
                statPill(
                    value: "\(sortedExercises.count)",
                    label: "EXERCISES"
                )
                statPill(
                    value: "\(sortedExercises.flatMap(\.sets).count)",
                    label: "TOTAL SETS"
                )
                statPill(
                    value: settings.displayWeightShort(session.totalVolumeKg),
                    label: settings.weightUnit.rawValue.uppercased() + " VOLUME"
                )
            }
        }
        .padding(16)
        .ggCard()
    }

    func exerciseDetailCard(_ exercise: ExerciseEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.exerciseName.uppercased())
                    .font(.ggSubtitle)
                    .foregroundColor(.ggText)
                Spacer()
                if exercise.sets.contains(where: { $0.isPR }) {
                    Label("PR", systemImage: "trophy.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.ggNeon)
                }
            }

            // Sets table
            VStack(spacing: 0) {
                HStack {
                    Text("SET").frame(width: 40, alignment: .leading)
                    Spacer()
                    Text("WEIGHT").frame(width: 90, alignment: .center)
                    Spacer()
                    Text("REPS").frame(width: 50, alignment: .center)
                    Spacer()
                    Text("VOL").frame(width: 80, alignment: .trailing)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.ggTextSecondary)
                .tracking(0.5)
                .padding(.bottom, 8)

                ForEach(exercise.sets.sorted(by: { $0.setNumber < $1.setNumber })) { set in
                    HStack {
                        Text("\(set.setNumber)")
                            .frame(width: 40, alignment: .leading)
                        Spacer()
                        HStack(spacing: 2) {
                            Text(settings.displayWeightShort(set.weightKg))
                            Text(settings.weightUnit.rawValue)
                                .foregroundColor(.ggTextSecondary)
                            if set.isPR {
                                Text("PR")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.ggNeon)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.ggNeon.opacity(0.15))
                                    .cornerRadius(3)
                            }
                        }
                        .frame(width: 90, alignment: .center)
                        Spacer()
                        Text("\(set.reps)")
                            .frame(width: 50, alignment: .center)
                        Spacer()
                        Text(settings.displayWeightShort(set.weightKg * Double(set.reps)))
                            .foregroundColor(.ggTextSecondary)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .font(.ggMonoSmall)
                    .foregroundColor(.ggText)
                    .padding(.vertical, 6)

                    if set.setNumber < (exercise.sets.map(\.setNumber).max() ?? 0) {
                        Divider().background(Color.ggBorder)
                    }
                }
            }
        }
        .padding(16)
        .ggCard()
    }

    func statPill(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.ggDisplaySmall)
                .foregroundColor(.ggAccent)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.ggTextSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

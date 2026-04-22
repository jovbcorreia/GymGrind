import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(\.modelContext) private var context
    @Environment(WorkoutViewModel.self) private var workoutVM
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var templates: [WorkoutTemplate]

    @State private var showNewWorkout = false
    @State private var showTemplates = false
    @State private var newWorkoutName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ggBackground.ignoresSafeArea()

                if workoutVM.isSessionActive, let session = workoutVM.activeSession {
                    ActiveWorkoutView(session: session)
                } else {
                    mainContent
                }
            }
            .navigationTitle("WORKOUT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ggBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(isPresented: $showNewWorkout) {
            newWorkoutSheet
        }
    }

    var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick start
                VStack(spacing: 12) {
                    Button {
                        HapticFeedback.impact(.heavy)
                        showNewWorkout = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("NEW WORKOUT")
                                .tracking(1)
                        }
                        .font(.system(size: 18, weight: .black))
                    }
                    .buttonStyle(GGButtonStyle())

                    if !templates.isEmpty {
                        Button("USE TEMPLATE") {
                            showTemplates = true
                        }
                        .buttonStyle(GGSecondaryButtonStyle())
                    }
                }
                .padding(.horizontal, 16)

                // Templates
                if !templates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TEMPLATES")
                            .font(.ggCaption)
                            .foregroundColor(.ggTextSecondary)
                            .tracking(1.5)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(templates) { template in
                                    templateCard(template)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }

                // History
                historySection

                Spacer(minLength: 80)
            }
            .padding(.top, 16)
        }
    }

    var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HISTORY")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)
                .padding(.horizontal, 16)

            if sessions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions) { session in
                        NavigationLink(destination: WorkoutDetailView(session: session)) {
                            sessionRow(session)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 40))
                .foregroundColor(.ggBorder)
            Text("No workouts yet")
                .font(.ggSubtitle)
                .foregroundColor(.ggTextSecondary)
            Text("Hit that button and get to work")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    var newWorkoutSheet: some View {
        NavigationStack {
            ZStack {
                Color.ggBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("NAME YOUR WORKOUT")
                        .font(.ggHeadline)
                        .foregroundColor(.ggText)

                    TextField("e.g. Push Day", text: $newWorkoutName)
                        .font(.ggTitle)
                        .foregroundColor(.ggText)
                        .padding(16)
                        .background(Color.ggSurface)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))

                    // Quick name suggestions
                    let suggestions = ["Push Day", "Pull Day", "Leg Day", "Upper Body", "Full Body", "Arms & Shoulders"]
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { s in
                                Button(s) { newWorkoutName = s }
                                    .font(.ggCaption)
                                    .foregroundColor(newWorkoutName == s ? .black : .ggAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(newWorkoutName == s ? Color.ggAccent : Color.ggSurface)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 4)
                    }

                    Spacer()

                    Button("START") {
                        let name = newWorkoutName.isEmpty ? "Workout" : newWorkoutName
                        workoutVM.startSession(name: name, context: context)
                        newWorkoutName = ""
                        showNewWorkout = false
                    }
                    .buttonStyle(GGButtonStyle())
                }
                .padding(24)
            }
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showNewWorkout = false }
                        .foregroundColor(.ggAccent)
                }
            }
            .toolbarBackground(Color.ggBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .presentationDetents([.medium])
    }

    func templateCard(_ template: WorkoutTemplate) -> some View {
        Button {
            workoutVM.startSession(name: template.name, context: context, template: template)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(template.name.uppercased())
                    .font(.ggSubtitle)
                    .foregroundColor(.ggText)
                Text("\(template.exerciseNames.count) exercises")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)

                ForEach(template.exerciseNames.prefix(3), id: \.self) { ex in
                    Text("· \(ex)")
                        .font(.system(size: 12))
                        .foregroundColor(.ggTextSecondary)
                }
                if template.exerciseNames.count > 3 {
                    Text("+\(template.exerciseNames.count - 3) more")
                        .font(.system(size: 11))
                        .foregroundColor(.ggTextSecondary.opacity(0.6))
                }
            }
            .padding(16)
            .frame(width: 160, alignment: .leading)
            .background(Color.ggSurface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ggBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    func sessionRow(_ session: WorkoutSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name.uppercased())
                    .font(.ggSubtitle)
                    .foregroundColor(.ggText)
                HStack(spacing: 8) {
                    Text(session.date, style: .date)
                    Text("·")
                    Text(session.formattedDuration)
                    Text("·")
                    Text("\(session.exercises.count) exercises")
                }
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(settings.displayWeightShort(session.totalVolumeKg))
                    .font(.ggMonoSmall)
                    .foregroundColor(.ggAccent)
                Text(settings.weightUnit.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(.ggTextSecondary)
            }
            Image(systemName: "chevron.right")
                .foregroundColor(.ggBorder)
                .font(.caption)
                .padding(.leading, 4)
        }
        .padding(16)
        .background(Color.ggSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ggBorder, lineWidth: 1))
    }
}

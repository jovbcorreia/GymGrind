import SwiftUI

struct ExerciseSearchView: View {
    @Environment(WorkoutViewModel.self) private var workoutVM
    @Environment(\.dismiss) private var dismiss

    let onSelect: (String) -> Void

    @State private var searchText = ""
    @State private var customName = ""

    var filtered: [String] {
        if searchText.isEmpty { return workoutVM.exerciseLibrary }
        return workoutVM.exerciseLibrary.filter {
            $0.localizedCaseInsensitiveContains(searchText)
        }
    }

    let categories: [(name: String, exercises: [String])] = [
        ("CHEST", ["Bench Press", "Incline Bench Press", "Decline Bench Press", "Push Up", "Cable Fly", "Dumbbell Fly"]),
        ("LEGS", ["Squat", "Leg Press", "Romanian Deadlift", "Leg Curl", "Leg Extension", "Hip Thrust", "Lunges"]),
        ("BACK", ["Deadlift", "Barbell Row", "Pull Up", "Lat Pulldown", "Seated Row", "Face Pull"]),
        ("SHOULDERS", ["Overhead Press", "Arnold Press", "Lateral Raise", "Front Raise", "Upright Row"]),
        ("ARMS", ["Bicep Curl", "Hammer Curl", "Tricep Pushdown", "Skull Crusher", "Tricep Dip"]),
        ("CORE", ["Plank", "Ab Wheel", "Crunch", "Leg Raise", "Russian Twist"])
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ggBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.ggTextSecondary)
                        TextField("Search exercises...", text: $searchText)
                            .font(.ggBody)
                            .foregroundColor(.ggText)
                    }
                    .padding(14)
                    .background(Color.ggSurface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Custom exercise
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CUSTOM EXERCISE")
                                    .font(.ggCaption)
                                    .foregroundColor(.ggTextSecondary)
                                    .tracking(1.5)

                                HStack {
                                    TextField("Exercise name", text: $customName)
                                        .font(.ggBody)
                                        .foregroundColor(.ggText)
                                    Button("ADD") {
                                        if !customName.trimmingCharacters(in: .whitespaces).isEmpty {
                                            onSelect(customName.trimmingCharacters(in: .whitespaces))
                                        }
                                    }
                                    .font(.ggCaption)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(customName.isEmpty ? Color.ggBorder : Color.ggAccent)
                                    .cornerRadius(8)
                                    .disabled(customName.isEmpty)
                                }
                                .padding(14)
                                .background(Color.ggSurface)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))
                            }
                            .padding(.horizontal, 16)

                            if searchText.isEmpty {
                                // Show by category
                                ForEach(categories, id: \.name) { category in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(category.name)
                                            .font(.ggCaption)
                                            .foregroundColor(.ggTextSecondary)
                                            .tracking(1.5)
                                            .padding(.horizontal, 16)

                                        VStack(spacing: 0) {
                                            ForEach(category.exercises, id: \.self) { exercise in
                                                Button {
                                                    onSelect(exercise)
                                                    HapticFeedback.impact(.light)
                                                } label: {
                                                    HStack {
                                                        Text(exercise)
                                                            .font(.ggBody)
                                                            .foregroundColor(.ggText)
                                                        Spacer()
                                                        Image(systemName: "plus.circle")
                                                            .foregroundColor(.ggAccent)
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 14)
                                                }

                                                if exercise != category.exercises.last {
                                                    Divider()
                                                        .background(Color.ggBorder)
                                                        .padding(.horizontal, 16)
                                                }
                                            }
                                        }
                                        .background(Color.ggSurface)
                                        .cornerRadius(12)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ggBorder, lineWidth: 1))
                                        .padding(.horizontal, 16)
                                    }
                                }
                            } else {
                                // Search results
                                VStack(spacing: 0) {
                                    ForEach(filtered, id: \.self) { exercise in
                                        Button {
                                            onSelect(exercise)
                                            HapticFeedback.impact(.light)
                                        } label: {
                                            HStack {
                                                Text(exercise)
                                                    .font(.ggBody)
                                                    .foregroundColor(.ggText)
                                                Spacer()
                                                Image(systemName: "plus.circle")
                                                    .foregroundColor(.ggAccent)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                        }

                                        if exercise != filtered.last {
                                            Divider().background(Color.ggBorder).padding(.horizontal, 16)
                                        }
                                    }

                                    if filtered.isEmpty {
                                        Text("No results. Use custom exercise above.")
                                            .font(.ggCaption)
                                            .foregroundColor(.ggTextSecondary)
                                            .padding(20)
                                    }
                                }
                                .background(Color.ggSurface)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ggBorder, lineWidth: 1))
                                .padding(.horizontal, 16)
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ggAccent)
                }
            }
            .toolbarBackground(Color.ggBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

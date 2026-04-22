import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context

    @Query private var sessions: [WorkoutSession]
    @Query private var foodEntries: [FoodEntry]
    @Query private var bodyMetrics: [BodyMetric]

    private let sbAuth    = SupabaseAuth.shared
    private let sbService = SupabaseService.shared

    @State private var showDeleteAlert = false
    @State private var showExportAlert = false
    @State private var showLogoutAlert = false
    @State private var calorieGoalStr = ""
    @State private var proteinGoalStr = ""
    @State private var carbsGoalStr = ""
    @State private var fatGoalStr = ""
    @State private var waterGoalStr = ""

    var body: some View {
        ZStack {
            Color.ggBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile
                    profileSection

                    // Units
                    unitsSection

                    // Nutrition Goals
                    nutritionGoalsSection

                    // Water Goal
                    waterGoalSection

                    // Stats
                    statsSection

                    // Data
                    dataSection

                    // App info
                    appInfoSection

                    Spacer(minLength: 60)
                }
                .padding(16)
                .padding(.top, 8)
            }
        }
        .navigationTitle("SETTINGS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.ggBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            calorieGoalStr = "\(settings.calorieGoal)"
            proteinGoalStr = String(format: "%.0f", settings.proteinGoal)
            carbsGoalStr   = String(format: "%.0f", settings.carbsGoal)
            fatGoalStr     = String(format: "%.0f", settings.fatGoal)
            waterGoalStr   = "\(settings.waterGoalML)"
        }
        .alert("Delete All Data?", isPresented: $showDeleteAlert) {
            Button("Delete Everything", role: .destructive) { deleteAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all workouts, nutrition logs, and body metrics. This cannot be undone.")
        }
    }

    var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("PROFILE")

            VStack(alignment: .leading, spacing: 8) {
                settingLabel("YOUR NAME")
                TextField("Name", text: $settings.userName)
                    .font(.ggBody)
                    .foregroundColor(.ggText)
                    .padding(14)
                    .background(Color.ggSurface2)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))
            }
        }
        .padding(16)
        .ggCard()
    }

    var unitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("UNITS")

            HStack(spacing: 12) {
                ForEach(WeightUnit.allCases, id: \.self) { unit in
                    Button(unit.rawValue.uppercased()) {
                        settings.weightUnit = unit
                        HapticFeedback.impact(.light)
                    }
                    .font(.ggTitle)
                    .foregroundColor(settings.weightUnit == unit ? .black : .ggAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(settings.weightUnit == unit ? Color.ggAccent : Color.ggSurface2)
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .ggCard()
    }

    var nutritionGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("NUTRITION GOALS")

            goalInput("DAILY CALORIES", value: $calorieGoalStr, suffix: "kcal") {
                settings.calorieGoal = Int(calorieGoalStr) ?? settings.calorieGoal
            }
            goalInput("PROTEIN", value: $proteinGoalStr, suffix: "g") {
                settings.proteinGoal = Double(proteinGoalStr) ?? settings.proteinGoal
            }
            goalInput("CARBOHYDRATES", value: $carbsGoalStr, suffix: "g") {
                settings.carbsGoal = Double(carbsGoalStr) ?? settings.carbsGoal
            }
            goalInput("FAT", value: $fatGoalStr, suffix: "g") {
                settings.fatGoal = Double(fatGoalStr) ?? settings.fatGoal
            }
        }
        .padding(16)
        .ggCard()
    }

    var waterGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("HYDRATION GOAL")

            goalInput("DAILY WATER", value: $waterGoalStr, suffix: "ml") {
                settings.waterGoalML = Int(waterGoalStr) ?? settings.waterGoalML
            }
        }
        .padding(16)
        .ggCard()
    }

    var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("YOUR STATS")

            HStack(spacing: 0) {
                statBlock(value: "\(sessions.count)", label: "WORKOUTS")
                statBlock(value: "\(foodEntries.count)", label: "FOOD LOGS")
                statBlock(value: "\(bodyMetrics.count)", label: "METRICS")
            }
        }
        .padding(16)
        .ggCard()
    }

    var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("CONTA")

            // Account info
            HStack {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.ggAccent)
                Text(sbAuth.userEmail ?? "—")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                Spacer()
                if sbService.isSyncing {
                    ProgressView().scaleEffect(0.7)
                } else {
                    Image(systemName: "checkmark.icloud.fill")
                        .foregroundColor(.ggNeon)
                        .font(.caption)
                }
            }
            .padding(14)
            .background(Color.ggSurface2)
            .cornerRadius(10)

            // Logout
            Button {
                showLogoutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }
                .foregroundColor(.ggAccent)
                .font(.ggBody)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.ggSurface2)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)

            sectionTitle("DATA")
                .padding(.top, 4)

            Button {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                    Text("Delete All Data")
                }
                .foregroundColor(.ggDanger)
                .font(.ggBody)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.ggDanger.opacity(0.1))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggDanger.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .ggCard()
        .alert("Sign Out?", isPresented: $showLogoutAlert) {
            Button("Sign Out", role: .destructive) { sbAuth.signOut() }
            Button("Cancel", role: .cancel) {}
        }
    }

    var appInfoSection: some View {
        VStack(spacing: 8) {
            Text("GYMGRIND")
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.ggAccent)
                .tracking(3)
            Text("Version 1.0")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
            Text("Built for athletes who mean business.")
                .font(.system(size: 11))
                .foregroundColor(.ggTextSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }

    // MARK: - Helpers
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.ggCaption)
            .foregroundColor(.ggTextSecondary)
            .tracking(1.5)
    }

    private func settingLabel(_ text: String) -> some View {
        Text(text)
            .font(.ggCaption)
            .foregroundColor(.ggTextSecondary)
            .tracking(1)
    }

    private func goalInput(_ label: String, value: Binding<String>, suffix: String, onCommit: @escaping () -> Void) -> some View {
        HStack {
            Text(label)
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(0.5)
            Spacer()
            HStack(spacing: 4) {
                TextField("0", text: value, onCommit: onCommit)
                    .font(.ggMonoSmall)
                    .foregroundColor(.ggText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                Text(suffix)
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.ggDisplaySmall)
                .foregroundColor(.ggAccent)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.ggTextSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    private func deleteAllData() {
        sessions.forEach { context.delete($0) }
        foodEntries.forEach { context.delete($0) }
        bodyMetrics.forEach { context.delete($0) }
        settings.waterLoggedML = 0
        HapticFeedback.notification(.warning)
    }
}

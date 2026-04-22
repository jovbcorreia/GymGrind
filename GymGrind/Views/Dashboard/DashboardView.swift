import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @Environment(WorkoutViewModel.self) private var workoutVM
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \FoodEntry.date, order: .reverse)      private var foodEntries: [FoodEntry]

    @State private var showStartWorkout = false

    // MARK: - Computed
    private var todaySessions: [WorkoutSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var todayCalories: Int {
        foodEntries
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.calories }
    }

    private var todayVolumeKg: Double {
        todaySessions.reduce(0) { $0 + $1.totalVolumeKg }
    }

    private var weekSessions: [WorkoutSession] {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return sessions.filter { $0.date >= startOfWeek }
    }

    private var weekStreak: Int { weekSessions.count }

    private var recentPRs: [(exercise: String, weight: Double, date: Date)] {
        var prs: [(exercise: String, weight: Double, date: Date)] = []
        var seen = Set<String>()

        for session in sessions.prefix(20) {
            for exercise in session.exercises {
                guard !seen.contains(exercise.exerciseName) else { continue }
                if let maxSet = exercise.sets.max(by: { $0.weightKg < $1.weightKg }),
                   maxSet.isPR || isPR(exercise: exercise.exerciseName, weight: maxSet.weightKg, before: session) {
                    prs.append((exercise.exerciseName, maxSet.weightKg, session.date))
                    seen.insert(exercise.exerciseName)
                    if prs.count >= 3 { return prs }
                }
            }
        }
        return prs
    }

    private func isPR(exercise: String, weight: Double, before session: WorkoutSession) -> Bool {
        let laterSessions = sessions.filter { $0.date > session.date }
        let higherWeights = laterSessions
            .flatMap(\.exercises)
            .filter { $0.exerciseName == exercise }
            .flatMap(\.sets)
            .map(\.weightKg)
        return higherWeights.allSatisfy { $0 <= weight }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.ggBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        todaySummaryCard
                        startWorkoutButton
                        streakCard
                        recentPRsCard
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Subviews
    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting())
                    .font(.ggSubtitle)
                    .foregroundColor(.ggTextSecondary)
                Text(settings.userName.isEmpty ? "Athlete" : settings.userName.uppercased())
                    .font(.ggDisplaySmall)
                    .foregroundColor(.ggText)
            }
            Spacer()
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.ggTextSecondary)
            }
        }
        .padding(.top, 16)
    }

    var todaySummaryCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("TODAY")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)
                Spacer()
                Text(Date(), style: .date)
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
            }
            .padding(.bottom, 16)

            HStack(spacing: 0) {
                statBlock(
                    value: "\(todayCalories)",
                    label: "KCAL",
                    sublabel: "of \(settings.calorieGoal)",
                    color: calorieColor
                )
                divider
                statBlock(
                    value: settings.displayWeightShort(todayVolumeKg),
                    label: settings.weightUnit.rawValue.uppercased() + " LIFTED",
                    sublabel: "total volume",
                    color: .ggAccent
                )
                divider
                statBlock(
                    value: "\(weekStreak)",
                    label: "SESSIONS",
                    sublabel: "this week",
                    color: .ggNeon
                )
            }

            // Calorie progress bar
            if todayCalories > 0 || settings.calorieGoal > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.ggBorder)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(calorieColor)
                            .frame(
                                width: min(
                                    geo.size.width * CGFloat(todayCalories) / CGFloat(max(settings.calorieGoal, 1)),
                                    geo.size.width
                                ),
                                height: 4
                            )
                            .animation(.easeOut, value: todayCalories)
                    }
                }
                .frame(height: 4)
                .padding(.top, 16)
            }
        }
        .padding(20)
        .ggCard()
    }

    var startWorkoutButton: some View {
        Button {
            HapticFeedback.impact(.heavy)
            NotificationCenter.default.post(name: .startWorkoutFromDashboard, object: nil)
        } label: {
            HStack {
                Image(systemName: "play.fill")
                    .font(.title3)
                Text("START WORKOUT")
                    .font(.system(size: 18, weight: .black))
                    .tracking(1)
            }
        }
        .buttonStyle(GGButtonStyle())
    }

    var streakCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("WEEK OVERVIEW")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)
                Spacer()
            }

            HStack(spacing: 6) {
                ForEach(weekDays(), id: \.date) { day in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(day.trained ? Color.ggAccent : Color.ggSurface2)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(day.shortName)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(day.trained ? .black : .ggTextSecondary)
                            )
                        if day.isToday {
                            Circle()
                                .fill(Color.ggAccent)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .ggCard()
    }

    var recentPRsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RECENT PRs")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundColor(.ggAccent)
                    .font(.caption)
            }

            if recentPRs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "dumbbell")
                            .font(.title)
                            .foregroundColor(.ggBorder)
                        Text("Log workouts to see your PRs")
                            .font(.ggCaption)
                            .foregroundColor(.ggTextSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentPRs.enumerated()), id: \.offset) { _, pr in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pr.exercise)
                                    .font(.ggSubtitle)
                                    .foregroundColor(.ggText)
                                Text(pr.date, style: .date)
                                    .font(.ggCaption)
                                    .foregroundColor(.ggTextSecondary)
                            }
                            Spacer()
                            Text(settings.displayWeight(pr.weight))
                                .font(.ggMono)
                                .foregroundColor(.ggAccent)
                            Text(settings.weightUnit.rawValue)
                                .font(.ggCaption)
                                .foregroundColor(.ggTextSecondary)
                        }
                        .padding(.vertical, 10)

                        if pr.exercise != recentPRs.last?.exercise {
                            Divider().background(Color.ggBorder)
                        }
                    }
                }
            }
        }
        .padding(20)
        .ggCard()
    }

    var divider: some View {
        Rectangle()
            .fill(Color.ggBorder)
            .frame(width: 1, height: 50)
    }

    // MARK: - Helpers
    private func statBlock(value: String, label: String, sublabel: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.ggDisplaySmall)
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(0.5)
            Text(sublabel)
                .font(.system(size: 10))
                .foregroundColor(.ggTextSecondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "GOOD MORNING"
        case 12..<17: return "GOOD AFTERNOON"
        case 17..<21: return "GOOD EVENING"
        default:      return "LATE NIGHT GRIND"
        }
    }

    private var calorieColor: Color {
        let ratio = Double(todayCalories) / Double(max(settings.calorieGoal, 1))
        if ratio > 1.1 { return .ggDanger }
        if ratio > 0.9 { return .ggNeon }
        return .ggAccent
    }

    struct WeekDay {
        let date: Date
        let shortName: String
        let trained: Bool
        let isToday: Bool
    }

    private func weekDays() -> [WeekDay] {
        let calendar = Calendar.current
        let today = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }

        return (0..<7).compactMap { offset -> WeekDay? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: weekStart) else { return nil }
            let isToday = calendar.isDateInToday(day)
            let isFuture = day > today && !isToday
            let trained = !isFuture && sessions.contains { calendar.isDate($0.date, inSameDayAs: day) }

            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            let name = String(formatter.string(from: day).prefix(1))

            return WeekDay(date: day, shortName: name, trained: trained, isToday: isToday)
        }
    }
}

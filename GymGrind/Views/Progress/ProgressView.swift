import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyMetric.date, order: .reverse)     private var bodyMetrics: [BodyMetric]

    @State private var selectedExercise: String? = nil
    @State private var showAddMetric = false

    var allExerciseNames: [String] {
        let names = sessions.flatMap(\.exercises).map(\.exerciseName)
        return Array(Set(names)).sorted()
    }

    var prsByExercise: [(exercise: String, weight: Double, date: Date)] {
        allExerciseNames.compactMap { name in
            let sets = sessions.flatMap(\.exercises)
                .filter { $0.exerciseName == name }
                .flatMap(\.sets)
            guard let best = sets.max(by: { $0.weightKg < $1.weightKg }),
                  let bestSession = sessions.first(where: {
                      $0.exercises.contains { $0.exerciseName == name && $0.sets.contains { $0.id == best.id } }
                  }) else { return nil }
            return (name, best.weightKg, bestSession.date)
        }
        .sorted(by: { $0.weight > $1.weight })
    }

    var weeklyVolumes: [(week: String, volume: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session -> Date in
            calendar.dateInterval(of: .weekOfYear, for: session.date)?.start ?? session.date
        }
        return grouped
            .sorted(by: { $0.key < $1.key })
            .suffix(8)
            .map { (key, weekSessions) in
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return (formatter.string(from: key), weekSessions.reduce(0) { $0 + $1.totalVolumeKg })
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ggBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        if sessions.isEmpty {
                            emptyState
                        } else {
                            // Volume chart
                            weeklyVolumeChart

                            // Exercise selector & chart
                            exerciseProgressSection

                            // PRs
                            prSection

                            // Body metrics
                            bodyMetricsSection
                        }

                        // Calendar heatmap
                        calendarHeatmap

                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("PROGRESS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ggBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddMetric) {
                AddBodyMetricView()
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.ggBorder)
            Text("No data yet")
                .font(.ggHeadline)
                .foregroundColor(.ggTextSecondary)
            Text("Complete workouts to see your progress charts")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(60)
    }

    // MARK: - Weekly Volume Chart
    var weeklyVolumeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WEEKLY VOLUME")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)

            if weeklyVolumes.isEmpty {
                Text("No data")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 140)
            } else {
                Chart {
                    ForEach(weeklyVolumes, id: \.week) { item in
                        BarMark(
                            x: .value("Week", item.week),
                            y: .value("Volume", settings.weightUnit == .kg ? item.volume : item.volume * 2.20462)
                        )
                        .foregroundStyle(Color.ggAccent.gradient)
                        .cornerRadius(4)
                    }
                }
                .chartXAxis {
                    AxisMarks { mark in
                        AxisValueLabel()
                            .foregroundStyle(Color.ggTextSecondary)
                            .font(.system(size: 9))
                    }
                }
                .chartYAxis {
                    AxisMarks { mark in
                        AxisValueLabel()
                            .foregroundStyle(Color.ggTextSecondary)
                            .font(.ggMonoSmall)
                        AxisGridLine().foregroundStyle(Color.ggBorder)
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(16)
        .ggCard()
    }

    // MARK: - Exercise Progress
    var exerciseProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EXERCISE PROGRESS")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)

            if allExerciseNames.isEmpty {
                Text("No exercises logged")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Exercise picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allExerciseNames, id: \.self) { name in
                            Button(name) {
                                selectedExercise = name
                            }
                            .font(.ggCaption)
                            .foregroundColor(selectedExercise == name ? .black : .ggTextSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedExercise == name ? Color.ggAccent : Color.ggSurface2)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                if let exercise = selectedExercise {
                    NavigationLink(destination: ExerciseProgressView(exerciseName: exercise)) {
                        HStack {
                            Text("View \(exercise) chart")
                                .font(.ggSubtitle)
                                .foregroundColor(.ggAccent)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.ggAccent)
                        }
                        .padding(12)
                        .background(Color.ggAccent.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    Text("Select an exercise above")
                        .font(.ggCaption)
                        .foregroundColor(.ggTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                        .onAppear {
                            if selectedExercise == nil {
                                selectedExercise = allExerciseNames.first
                            }
                        }
                }
            }
        }
        .padding(16)
        .ggCard()
    }

    // MARK: - PRs
    var prSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BEST LIFTS (PRs)")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)
                Spacer()
                Image(systemName: "trophy.fill")
                    .foregroundColor(.ggAccent)
                    .font(.caption)
            }

            if prsByExercise.isEmpty {
                Text("No PRs yet")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(prsByExercise.enumerated()), id: \.offset) { index, pr in
                        HStack {
                            Text("\(index + 1)")
                                .font(.ggMonoSmall)
                                .foregroundColor(.ggTextSecondary)
                                .frame(width: 24, alignment: .leading)

                            Text(pr.exercise)
                                .font(.ggSubtitle)
                                .foregroundColor(.ggText)

                            Spacer()

                            Text(settings.displayWeight(pr.weight))
                                .font(.ggMono)
                                .foregroundColor(.ggAccent)
                            Text(settings.weightUnit.rawValue)
                                .font(.ggCaption)
                                .foregroundColor(.ggTextSecondary)
                        }
                        .padding(.vertical, 10)

                        if index < prsByExercise.count - 1 {
                            Divider().background(Color.ggBorder)
                        }
                    }
                }
            }
        }
        .padding(16)
        .ggCard()
    }

    // MARK: - Body Metrics
    var bodyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("BODY METRICS")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)
                Spacer()
                Button {
                    showAddMetric = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.ggAccent)
                }
            }

            if bodyMetrics.isEmpty {
                Button("Log Body Weight") {
                    showAddMetric = true
                }
                .font(.ggCaption)
                .foregroundColor(.ggAccent)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 12)
            } else {
                // Weight chart
                if bodyMetrics.count > 1 {
                    Chart {
                        ForEach(bodyMetrics.reversed()) { metric in
                            LineMark(
                                x: .value("Date", metric.date),
                                y: .value("Weight", settings.weightUnit == .kg ? metric.weightKg : metric.weightKg * 2.20462)
                            )
                            .foregroundStyle(Color.ggNeon)
                            .lineStyle(StrokeStyle(lineWidth: 2))

                            PointMark(
                                x: .value("Date", metric.date),
                                y: .value("Weight", settings.weightUnit == .kg ? metric.weightKg : metric.weightKg * 2.20462)
                            )
                            .foregroundStyle(Color.ggNeon)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                            AxisValueLabel(format: .dateTime.month().day())
                                .foregroundStyle(Color.ggTextSecondary)
                                .font(.system(size: 9))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { mark in
                            AxisValueLabel()
                                .foregroundStyle(Color.ggTextSecondary)
                                .font(.ggMonoSmall)
                            AxisGridLine().foregroundStyle(Color.ggBorder)
                        }
                    }
                    .frame(height: 140)
                }

                // Latest metric
                if let latest = bodyMetrics.first {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CURRENT")
                                .font(.ggCaption)
                                .foregroundColor(.ggTextSecondary)
                                .tracking(1)
                            Text(settings.displayWeight(latest.weightKg))
                                .font(.ggMono)
                                .foregroundColor(.ggNeon)
                            + Text(" \(settings.weightUnit.rawValue)")
                                .font(.ggCaption)
                                .foregroundColor(.ggTextSecondary)
                        }
                        Spacer()
                        Text(latest.date, style: .date)
                            .font(.ggCaption)
                            .foregroundColor(.ggTextSecondary)
                    }
                }
            }
        }
        .padding(16)
        .ggCard()
    }

    // MARK: - Calendar Heatmap
    var calendarHeatmap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TRAINING FREQUENCY")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)

            let calendar = Calendar.current
            let today = Date()
            let daysBack = 63  // 9 weeks

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 4), count: 7), spacing: 4) {
                ForEach((-daysBack..<0).reversed(), id: \.self) { offset in
                    if let day = calendar.date(byAdding: .day, value: offset, to: today) {
                        let count = sessions.filter { calendar.isDate($0.date, inSameDayAs: day) }.count
                        let isToday = calendar.isDateInToday(day)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatColor(count: count, isToday: isToday))
                            .frame(height: 32)
                            .overlay(
                                isToday ?
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.ggAccent, lineWidth: 1)
                                : nil
                            )
                    }
                }
            }

            // Legend
            HStack(spacing: 8) {
                Text("Less")
                    .font(.system(size: 10))
                    .foregroundColor(.ggTextSecondary)
                ForEach([0, 1, 2, 3], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatColor(count: level, isToday: false))
                        .frame(width: 12, height: 12)
                }
                Text("More")
                    .font(.system(size: 10))
                    .foregroundColor(.ggTextSecondary)
            }
        }
        .padding(16)
        .ggCard()
    }

    private func heatColor(count: Int, isToday: Bool) -> Color {
        if isToday && count == 0 { return Color.ggSurface2 }
        switch count {
        case 0:  return Color.ggSurface2
        case 1:  return Color.ggAccent.opacity(0.35)
        case 2:  return Color.ggAccent.opacity(0.65)
        default: return Color.ggAccent
        }
    }
}

// MARK: - Add Body Metric
struct AddBodyMetricView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var weightStr = ""
    @State private var bodyFatStr = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ggBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text("LOG BODY METRICS")
                        .font(.ggHeadline)
                        .foregroundColor(.ggText)

                    inputField("BODY WEIGHT (\(settings.weightUnit.rawValue.uppercased()))",
                               value: $weightStr, keyboard: .decimalPad)
                    inputField("BODY FAT % (optional)", value: $bodyFatStr, keyboard: .decimalPad)

                    Spacer()

                    Button("SAVE") {
                        guard let weight = Double(weightStr) else { return }
                        let weightKg = settings.inputToKg(weight)
                        let bf = Double(bodyFatStr)
                        let metric = BodyMetric(weightKg: weightKg, bodyFatPercent: bf)
                        context.insert(metric)
                        dismiss()
                    }
                    .buttonStyle(GGButtonStyle())
                    .disabled(weightStr.isEmpty)
                    .opacity(weightStr.isEmpty ? 0.4 : 1)
                }
                .padding(24)
            }
            .navigationTitle("Body Metrics")
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
        .presentationDetents([.medium])
    }

    func inputField(_ title: String, value: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)
            TextField("0", text: value)
                .font(.ggMono)
                .foregroundColor(.ggText)
                .keyboardType(keyboard)
                .padding(14)
                .background(Color.ggSurface)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))
        }
    }
}

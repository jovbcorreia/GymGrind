import SwiftUI
import SwiftData
import Charts

struct ExerciseProgressView: View {
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \WorkoutSession.date, order: .forward) private var sessions: [WorkoutSession]

    let exerciseName: String

    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let maxWeight: Double
        let totalVolume: Double
        let totalReps: Int
    }

    var dataPoints: [DataPoint] {
        sessions.compactMap { session -> DataPoint? in
            let exercises = session.exercises.filter { $0.exerciseName == exerciseName }
            guard !exercises.isEmpty else { return nil }
            let allSets = exercises.flatMap(\.sets)
            let maxW = allSets.map(\.weightKg).max() ?? 0
            let vol = allSets.reduce(0.0) { $0 + ($1.weightKg * Double($1.reps)) }
            let reps = allSets.reduce(0) { $0 + $1.reps }
            return DataPoint(date: session.date, maxWeight: maxW, totalVolume: vol, totalReps: reps)
        }
    }

    var currentPR: Double { dataPoints.map(\.maxWeight).max() ?? 0 }

    @State private var selectedMetric: Int = 0  // 0: weight, 1: volume

    var body: some View {
        ZStack {
            Color.ggBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // PR header
                    prHeader

                    // Metric toggle
                    HStack(spacing: 0) {
                        metricTab("MAX WEIGHT", index: 0)
                        metricTab("VOLUME", index: 1)
                    }
                    .background(Color.ggSurface)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))
                    .padding(.horizontal, 16)

                    // Chart
                    progressChart

                    // Session history
                    sessionHistory

                    Spacer(minLength: 60)
                }
                .padding(.top, 12)
            }
        }
        .navigationTitle(exerciseName.uppercased())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.ggBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    var prHeader: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(settings.displayWeight(currentPR))
                    .font(.ggDisplayMedium)
                    .foregroundColor(.ggAccent)
                Text("BEST WEIGHT (\(settings.weightUnit.rawValue.uppercased()))")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)

            Rectangle().fill(Color.ggBorder).frame(width: 1, height: 50)

            VStack(spacing: 4) {
                Text("\(dataPoints.count)")
                    .font(.ggDisplayMedium)
                    .foregroundColor(.ggNeon)
                Text("SESSIONS")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .ggCard()
        .padding(.horizontal, 16)
    }

    var progressChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            if dataPoints.isEmpty {
                Text("Not enough data to show chart")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        let yValue = selectedMetric == 0
                            ? (settings.weightUnit == .kg ? point.maxWeight : point.maxWeight * 2.20462)
                            : (settings.weightUnit == .kg ? point.totalVolume : point.totalVolume * 2.20462)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", yValue)
                        )
                        .foregroundStyle(Color.ggAccent)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", yValue)
                        )
                        .foregroundStyle(Color.ggAccent.opacity(0.1))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Value", yValue)
                        )
                        .foregroundStyle(Color.ggAccent)
                        .symbolSize(40)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.ggTextSecondary)
                            .font(.system(size: 9))
                        AxisGridLine().foregroundStyle(Color.ggBorder)
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
                .frame(height: 200)
            }
        }
        .padding(16)
        .ggCard()
        .padding(.horizontal, 16)
    }

    var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SESSION HISTORY")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)

            VStack(spacing: 0) {
                ForEach(Array(dataPoints.reversed().enumerated()), id: \.element.id) { index, point in
                    HStack {
                        Text(point.date, style: .date)
                            .font(.ggCaption)
                            .foregroundColor(.ggTextSecondary)

                        Spacer()

                        Text(settings.displayWeight(point.maxWeight))
                            .font(.ggMonoSmall)
                            .foregroundColor(.ggText)
                        Text(settings.weightUnit.rawValue)
                            .font(.ggCaption)
                            .foregroundColor(.ggTextSecondary)

                        Spacer()

                        Text("\(point.totalReps) reps")
                            .font(.ggMonoSmall)
                            .foregroundColor(.ggTextSecondary)
                    }
                    .padding(.vertical, 10)

                    if index < dataPoints.count - 1 {
                        Divider().background(Color.ggBorder)
                    }
                }
            }
        }
        .padding(16)
        .ggCard()
        .padding(.horizontal, 16)
    }

    func metricTab(_ title: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selectedMetric = index }
        } label: {
            Text(title)
                .font(.ggCaption)
                .tracking(1)
                .foregroundColor(selectedMetric == index ? .black : .ggTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(selectedMetric == index ? Color.ggAccent : Color.clear)
                .cornerRadius(9)
        }
    }
}

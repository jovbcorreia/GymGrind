import SwiftUI
import SwiftData
import Charts

struct NutritionView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: \FoodEntry.date, order: .reverse) private var allEntries: [FoodEntry]
    @State private var nutritionVM = NutritionViewModel()
    @State private var showAddFood = false
    @State private var selectedMeal: MealType = .breakfast
    @State private var waterAmount: Int = 0

    private var todayEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var totalCalories: Int { todayEntries.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { todayEntries.reduce(0) { $0 + $1.proteinG } }
    private var totalCarbs: Double   { todayEntries.reduce(0) { $0 + $1.carbsG } }
    private var totalFat: Double     { todayEntries.reduce(0) { $0 + $1.fatG } }
    private var remaining: Int       { settings.calorieGoal - totalCalories }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ggBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        calorieRingCard
                        macroBreakdownCard
                        waterCard
                        mealsSection
                        weeklyAverageCard
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showAddFood = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.black)
                                .frame(width: 56, height: 56)
                                .background(Color.ggAccent)
                                .clipShape(Circle())
                                .shadow(color: Color.ggAccent.opacity(0.4), radius: 12, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("NUTRITION")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ggBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddFood) {
                AddFoodView(defaultMeal: selectedMeal)
            }
            .onAppear {
                settings.checkAndResetWater()
            }
        }
    }

    // MARK: - Calorie Ring Card
    var calorieRingCard: some View {
        HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(Color.ggSurface2, lineWidth: 12)
                    .frame(width: 110, height: 110)

                Circle()
                    .trim(from: 0, to: min(CGFloat(totalCalories) / CGFloat(max(settings.calorieGoal, 1)), 1))
                    .stroke(
                        calorieRingColor.gradient,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.5), value: totalCalories)

                VStack(spacing: 0) {
                    Text("\(totalCalories)")
                        .font(.system(size: 24, weight: .black, design: .monospaced))
                        .foregroundColor(.ggText)
                    Text("kcal")
                        .font(.ggCaption)
                        .foregroundColor(.ggTextSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                calorieRow(label: "CONSUMED", value: "\(totalCalories)", color: calorieRingColor)
                calorieRow(label: "GOAL", value: "\(settings.calorieGoal)", color: .ggTextSecondary)
                calorieRow(
                    label: remaining >= 0 ? "REMAINING" : "OVER",
                    value: "\(abs(remaining))",
                    color: remaining >= 0 ? .ggNeon : .ggDanger
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .ggCard()
    }

    // MARK: - Macro Breakdown
    var macroBreakdownCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("MACROS TODAY")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)
                Spacer()
            }

            HStack(spacing: 8) {
                macroBar(label: "PROTEIN", value: totalProtein, goal: settings.proteinGoal, color: .ggAccent)
                macroBar(label: "CARBS",   value: totalCarbs,   goal: settings.carbsGoal,   color: .ggNeon)
                macroBar(label: "FAT",     value: totalFat,     goal: settings.fatGoal,     color: Color(hex: "#FF9500"))
            }
        }
        .padding(20)
        .ggCard()
    }

    // MARK: - Water
    var waterCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("WATER INTAKE")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)
                Spacer()
                Text("\(settings.waterLoggedML) / \(settings.waterGoalML) ml")
                    .font(.ggMonoSmall)
                    .foregroundColor(.ggText)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.ggSurface2)
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#0A84FF").gradient)
                        .frame(
                            width: min(
                                geo.size.width * CGFloat(settings.waterLoggedML) / CGFloat(max(settings.waterGoalML, 1)),
                                geo.size.width
                            ),
                            height: 10
                        )
                        .animation(.easeOut, value: settings.waterLoggedML)
                }
            }
            .frame(height: 10)

            HStack(spacing: 8) {
                ForEach([250, 330, 500], id: \.self) { ml in
                    Button("+\(ml)ml") {
                        settings.waterLoggedML += ml
                        HapticFeedback.impact(.light)
                    }
                    .font(.ggCaption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#0A84FF").opacity(0.3))
                    .cornerRadius(8)
                }

                Spacer()

                Button("Reset") {
                    settings.waterLoggedML = 0
                }
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
            }
        }
        .padding(16)
        .ggCard()
    }

    // MARK: - Meals
    var mealsSection: some View {
        VStack(spacing: 12) {
            ForEach(MealType.allCases, id: \.self) { meal in
                MealSection(
                    meal: meal,
                    entries: todayEntries.filter { $0.mealType == meal },
                    onAdd: {
                        selectedMeal = meal
                        showAddFood = true
                    },
                    onDelete: { entry in
                        context.delete(entry)
                    }
                )
            }
        }
    }

    // MARK: - Weekly Average
    var weeklyAverageCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("7-DAY AVERAGE")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)

            let avg = nutritionVM.weeklyAverageCalories(from: allEntries)
            let avgMacros = nutritionVM.weeklyAverageMacros(from: allEntries)

            HStack(spacing: 0) {
                avgStat(value: "\(avg)", label: "KCAL/DAY", color: .ggAccent)
                avgStat(value: String(format: "%.0fg", avgMacros.protein), label: "PROTEIN", color: .ggAccent)
                avgStat(value: String(format: "%.0fg", avgMacros.carbs),   label: "CARBS",   color: .ggNeon)
                avgStat(value: String(format: "%.0fg", avgMacros.fat),     label: "FAT",     color: Color(hex: "#FF9500"))
            }
        }
        .padding(16)
        .ggCard()
    }

    // MARK: - Helpers
    private func calorieRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(0.5)
            Spacer()
            Text(value)
                .font(.ggMonoSmall)
                .foregroundColor(color)
            Text("kcal")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
        }
    }

    private func macroBar(label: String, value: Double, goal: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(Int(value))g")
                .font(.ggMonoSmall)
                .foregroundColor(color)

            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.ggSurface2)
                        .frame(width: 28)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(
                            width: 28,
                            height: min(geo.size.height * CGFloat(value / max(goal, 1)), geo.size.height)
                        )
                        .animation(.easeOut, value: value)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)

            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.ggTextSecondary)
                .tracking(0.5)

            Text("/ \(Int(goal))g")
                .font(.system(size: 9))
                .foregroundColor(.ggTextSecondary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    private var calorieRingColor: Color {
        let ratio = Double(totalCalories) / Double(max(settings.calorieGoal, 1))
        if ratio > 1.1 { return .ggDanger }
        if ratio > 0.85 { return .ggNeon }
        return .ggAccent
    }

    private func avgStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.ggMonoSmall)
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.ggTextSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Section
struct MealSection: View {
    let meal: MealType
    let entries: [FoodEntry]
    let onAdd: () -> Void
    let onDelete: (FoodEntry) -> Void

    @State private var isExpanded = true

    private var totalCals: Int { entries.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(spacing: 0) {
            // Meal header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: meal.icon)
                        .foregroundColor(.ggAccent)
                        .frame(width: 20)
                    Text(meal.rawValue.uppercased())
                        .font(.ggSubtitle)
                        .foregroundColor(.ggText)
                    Spacer()
                    if totalCals > 0 {
                        Text("\(totalCals) kcal")
                            .font(.ggMonoSmall)
                            .foregroundColor(.ggTextSecondary)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.ggTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    Button {
                        onAdd()
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.ggAccent)
                            .padding(6)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                if entries.isEmpty {
                    Text("Nothing logged yet")
                        .font(.ggCaption)
                        .foregroundColor(.ggTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                } else {
                    VStack(spacing: 0) {
                        Divider().background(Color.ggBorder)
                        ForEach(entries) { entry in
                            foodRow(entry)
                        }
                    }
                }
            }
        }
        .background(Color.ggSurface)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.ggBorder, lineWidth: 1))
    }

    @ViewBuilder
    func foodRow(_ entry: FoodEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.ggBody)
                    .foregroundColor(.ggText)
                HStack(spacing: 6) {
                    Text("P: \(Int(entry.proteinG))g")
                    Text("C: \(Int(entry.carbsG))g")
                    Text("F: \(Int(entry.fatG))g")
                }
                .font(.system(size: 11))
                .foregroundColor(.ggTextSecondary)
            }
            Spacer()
            Text("\(entry.calories)")
                .font(.ggMonoSmall)
                .foregroundColor(.ggText)
            Text("kcal")
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)

            Button {
                onDelete(entry)
                HapticFeedback.impact(.light)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.ggDanger.opacity(0.7))
                    .padding(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)

        Divider().background(Color.ggBorder)
    }
}

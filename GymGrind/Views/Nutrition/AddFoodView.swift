import SwiftUI

struct AddFoodView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var defaultMeal: MealType = .breakfast

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var selectedMeal: MealType

    init(defaultMeal: MealType = .breakfast) {
        self.defaultMeal = defaultMeal
        _selectedMeal = State(initialValue: defaultMeal)
    }

    // Quick presets
    let presets: [(name: String, cal: Int, p: Double, c: Double, f: Double)] = [
        ("Chicken Breast (100g)", 165, 31, 0, 3.6),
        ("Rice (100g cooked)",    130, 2.7, 28, 0.3),
        ("Egg (1 whole)",         70,  6,  0.5, 5),
        ("Oat (100g)",            389, 17, 66, 7),
        ("Broccoli (100g)",       34,  2.8, 7, 0.4),
        ("Whole Milk (250ml)",    150, 8,  12, 8),
        ("Banana (1 medium)",     89,  1.1, 23, 0.3),
        ("Greek Yogurt (150g)",   100, 17, 6,  0.5)
    ]

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !(calories.isEmpty && protein.isEmpty && carbs.isEmpty && fat.isEmpty)
    }

    var autoCalories: Int {
        let p = (Double(protein) ?? 0) * 4
        let c = (Double(carbs) ?? 0) * 4
        let f = (Double(fat) ?? 0) * 9
        return Int(p + c + f)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ggBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Meal selector
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("MEAL")
                            HStack(spacing: 8) {
                                ForEach(MealType.allCases, id: \.self) { meal in
                                    Button {
                                        selectedMeal = meal
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: meal.icon)
                                            Text(meal.rawValue)
                                                .font(.system(size: 10, weight: .semibold))
                                        }
                                        .foregroundColor(selectedMeal == meal ? .black : .ggTextSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedMeal == meal ? Color.ggAccent : Color.ggSurface)
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        // Food name
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("FOOD NAME")
                            TextField("e.g. Chicken Breast", text: $name)
                                .font(.ggBody)
                                .foregroundColor(.ggText)
                                .padding(14)
                                .background(Color.ggSurface)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))
                        }

                        // Macros
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("MACROS (grams)")
                            HStack(spacing: 12) {
                                macroField("Protein", value: $protein, color: .ggAccent)
                                macroField("Carbs",   value: $carbs,   color: .ggNeon)
                                macroField("Fat",     value: $fat,     color: Color(hex: "#FF9500"))
                            }

                            // Auto-calc calorie hint
                            if !protein.isEmpty || !carbs.isEmpty || !fat.isEmpty {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                    Text("Auto-calculated: \(autoCalories) kcal")
                                        .font(.ggCaption)
                                }
                                .foregroundColor(.ggAccent)
                                .onTapGesture {
                                    calories = "\(autoCalories)"
                                }
                            }
                        }

                        // Calories override
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("CALORIES (kcal)")
                            TextField(calories.isEmpty ? "\(autoCalories)" : "Override", text: $calories)
                                .font(.ggMono)
                                .foregroundColor(.ggText)
                                .keyboardType(.numberPad)
                                .padding(14)
                                .background(Color.ggSurface)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.ggBorder, lineWidth: 1))
                        }

                        // Quick presets
                        VStack(alignment: .leading, spacing: 8) {
                            sectionLabel("QUICK ADD")
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(presets, id: \.name) { preset in
                                    Button {
                                        name = preset.name
                                        calories = "\(preset.cal)"
                                        protein = String(format: "%.1f", preset.p)
                                        carbs   = String(format: "%.1f", preset.c)
                                        fat     = String(format: "%.1f", preset.f)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(preset.name)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.ggText)
                                                .lineLimit(2)
                                            Text("\(preset.cal) kcal · P:\(Int(preset.p))g")
                                                .font(.system(size: 10))
                                                .foregroundColor(.ggTextSecondary)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(Color.ggSurface)
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.ggBorder, lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Spacer(minLength: 20)

                        Button("ADD FOOD") {
                            saveEntry()
                        }
                        .buttonStyle(GGButtonStyle())
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.4)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Food")
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

    func saveEntry() {
        let cal = Int(calories) ?? autoCalories
        let entry = FoodEntry(
            meal: selectedMeal,
            name: name.trimmingCharacters(in: .whitespaces),
            calories: cal,
            proteinG: Double(protein) ?? 0,
            carbsG: Double(carbs) ?? 0,
            fatG: Double(fat) ?? 0
        )
        context.insert(entry)
        HapticFeedback.notification(.success)
        dismiss()
    }

    func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.ggCaption)
            .foregroundColor(.ggTextSecondary)
            .tracking(1.5)
    }

    func macroField(_ label: String, value: Binding<String>, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
                .tracking(0.5)
            TextField("0", text: value)
                .font(.ggMono)
                .foregroundColor(.ggText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .background(Color.ggSurface)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
        }
    }
}

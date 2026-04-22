import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var page: Int = 0
    @State private var userName: String = ""
    @State private var selectedUnit: WeightUnit = .kg
    @State private var calorieGoal: String = "2500"
    @State private var bodyWeightStr: String = ""

    var body: some View {
        ZStack {
            Color.ggBackground.ignoresSafeArea()

            TabView(selection: $page) {
                welcomePage.tag(0)
                profilePage.tag(1)
                goalsPage.tag(2)
                readyPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            // Page dots
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Color.ggAccent : Color.ggBorder)
                            .frame(width: i == page ? 24 : 8, height: 8)
                            .animation(.easeInOut, value: page)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Pages
    var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            ZStack {
                Circle()
                    .fill(Color.ggAccent.opacity(0.15))
                    .frame(width: 140, height: 140)
                Text("GG")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundColor(.ggAccent)
            }
            .padding(.bottom, 40)

            Text("GYMGRIND")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundColor(.ggText)
                .tracking(4)

            Text("Track. Grind. Grow.")
                .font(.ggSubtitle)
                .foregroundColor(.ggTextSecondary)
                .padding(.top, 8)

            Spacer()

            VStack(spacing: 16) {
                featurePill(icon: "dumbbell.fill", text: "Log workouts & track PRs")
                featurePill(icon: "chart.line.uptrend.xyaxis", text: "Visualize your progress")
                featurePill(icon: "fork.knife", text: "Monitor nutrition & calories")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("GET STARTED") { withAnimation { page = 1 } }
                .buttonStyle(GGButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 80)
        }
    }

    var profilePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("01")
                    .font(.ggMonoLarge)
                    .foregroundColor(.ggAccent)
                Text("WHO ARE\nYOU?")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.ggText)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)

            VStack(alignment: .leading, spacing: 8) {
                Text("NAME")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)

                TextField("Your name", text: $userName)
                    .font(.ggHeadline)
                    .foregroundColor(.ggText)
                    .padding(16)
                    .background(Color.ggSurface)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.ggBorder, lineWidth: 1)
                    )
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("WEIGHT UNITS")
                    .font(.ggCaption)
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1.5)

                HStack(spacing: 12) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Button(unit.rawValue.uppercased()) {
                            selectedUnit = unit
                        }
                        .font(.ggTitle)
                        .foregroundColor(selectedUnit == unit ? .black : .ggAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedUnit == unit ? Color.ggAccent : Color.ggSurface)
                        .cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("CONTINUE") {
                withAnimation { page = 2 }
            }
            .buttonStyle(GGButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
            .disabled(userName.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(userName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
        }
    }

    var goalsPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("02")
                    .font(.ggMonoLarge)
                    .foregroundColor(.ggAccent)
                Text("SET YOUR\nGOALS")
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.ggText)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)

            VStack(spacing: 16) {
                goalField(title: "DAILY CALORIE GOAL", value: $calorieGoal, suffix: "kcal")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button("CONTINUE") {
                withAnimation { page = 3 }
            }
            .buttonStyle(GGButtonStyle())
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
        }
    }

    var readyPage: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.ggNeon.opacity(0.15))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark")
                    .font(.system(size: 52, weight: .black))
                    .foregroundColor(.ggNeon)
            }
            .padding(.bottom, 32)

            Text("YOU'RE READY")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.ggText)

            Text("Let's get to work,\n\(userName.isEmpty ? "Athlete" : userName).")
                .font(.ggSubtitle)
                .foregroundColor(.ggTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            Spacer()

            Button("START GRINDING") {
                saveSettings()
            }
            .buttonStyle(GGButtonStyle(color: .ggNeon))
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
        }
    }

    // MARK: - Helpers
    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.ggAccent)
                .frame(width: 24)
            Text(text)
                .font(.ggBody)
                .foregroundColor(.ggText)
            Spacer()
        }
        .padding(14)
        .background(Color.ggSurface)
        .cornerRadius(10)
    }

    private func goalField(title: String, value: Binding<String>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)

            HStack {
                TextField("0", text: value)
                    .font(.ggMono)
                    .foregroundColor(.ggText)
                    .keyboardType(.numberPad)
                Text(suffix)
                    .font(.ggSubtitle)
                    .foregroundColor(.ggTextSecondary)
            }
            .padding(16)
            .background(Color.ggSurface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.ggBorder, lineWidth: 1)
            )
        }
    }

    private func saveSettings() {
        settings.userName = userName.trimmingCharacters(in: .whitespaces)
        settings.weightUnit = selectedUnit
        settings.calorieGoal = Int(calorieGoal) ?? 2500
        settings.onboardingDone = true
    }
}

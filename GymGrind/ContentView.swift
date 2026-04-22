import SwiftUI

struct ContentView: View {
    @Environment(WorkoutViewModel.self) private var workoutVM
    @EnvironmentObject private var settings: AppSettings
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            WorkoutTabView()
                .tabItem {
                    Label("Workout", systemImage: "dumbbell.fill")
                }
                .tag(1)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

            NutritionView()
                .tabItem {
                    Label("Nutrition", systemImage: "fork.knife")
                }
                .tag(3)
        }
        .tint(.ggAccent)
        .background(Color.ggBackground)
        .onReceive(NotificationCenter.default.publisher(for: .startWorkoutFromDashboard)) { _ in
            selectedTab = 1
        }
    }
}

extension Notification.Name {
    static let startWorkoutFromDashboard = Notification.Name("startWorkoutFromDashboard")
}

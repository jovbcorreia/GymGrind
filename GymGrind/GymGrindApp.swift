import SwiftUI
import SwiftData

@main
struct GymGrindApp: App {
    @StateObject private var settings = AppSettings.shared
    @State private var workoutVM = WorkoutViewModel()
    @State private var nutritionVM = NutritionViewModel()
    @State private var supabaseAuth = SupabaseAuth.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            WorkoutSession.self,
            ExerciseEntry.self,
            SetEntry.self,
            FoodEntry.self,
            BodyMetric.self,
            WorkoutTemplate.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if !supabaseAuth.isLoggedIn {
                    // Não autenticado → ecrã de login
                    AuthView()
                        .environmentObject(settings)
                } else if !settings.onboardingDone {
                    // Logado mas onboarding não feito
                    OnboardingView()
                        .environmentObject(settings)
                } else {
                    // App principal
                    ContentView()
                        .environment(workoutVM)
                        .environment(nutritionVM)
                        .environmentObject(settings)
                        .environment(supabaseAuth)
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.2), value: supabaseAuth.isLoggedIn)
        }
        .modelContainer(sharedModelContainer)
    }
}

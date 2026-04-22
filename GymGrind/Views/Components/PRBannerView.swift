import SwiftUI

struct PRBannerView: View {
    let exerciseName: String

    @State private var offset: CGFloat = -100
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trophy.fill")
                .font(.title2)
                .foregroundColor(.black)

            VStack(alignment: .leading, spacing: 2) {
                Text("NEW PERSONAL RECORD!")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
                    .tracking(0.5)
                Text(exerciseName)
                    .font(.ggCaption)
                    .foregroundColor(.black.opacity(0.7))
            }

            Spacer()

            Image(systemName: "star.fill")
                .foregroundColor(.black.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.ggNeon)
        .cornerRadius(12)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                offset = 0
                opacity = 1
            }
        }
    }
}

struct RestTimerBanner: View {
    @Environment(WorkoutViewModel.self) private var workoutVM

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "timer.circle.fill")
                .font(.title2)
                .foregroundColor(.ggAccent)

            VStack(alignment: .leading, spacing: 2) {
                Text("REST TIMER")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.ggTextSecondary)
                    .tracking(1)
                Text(workoutVM.restTimerFormatted)
                    .font(.ggMono)
                    .foregroundColor(.ggText)
            }

            Spacer()

            // Quick adjust buttons
            HStack(spacing: 8) {
                Button("+30s") {
                    workoutVM.restTimerSeconds += 30
                }
                .font(.ggCaption)
                .foregroundColor(.ggAccent)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.ggSurface2)
                .cornerRadius(8)

                Button("Skip") {
                    workoutVM.stopRestTimer()
                    HapticFeedback.impact(.medium)
                }
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.ggSurface2)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.ggSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.ggAccent.opacity(0.3), lineWidth: 1)
        )
        .overlay(
            // Progress bar at bottom
            GeometryReader { geo in
                VStack {
                    Spacer()
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.ggBorder)
                            .frame(height: 2)
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.ggAccent)
                            .frame(
                                width: geo.size.width * CGFloat(workoutVM.restTimerSeconds) / CGFloat(max(workoutVM.selectedRestDuration, 1)),
                                height: 2
                            )
                    }
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Confetti Particles (lightweight, no dependencies)
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isActive = false

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var color: Color
        var rotation: Double
        var scale: CGFloat
        var velocity: CGPoint
    }

    let colors: [Color] = [.ggAccent, .ggNeon, .white, Color(hex: "#FFD700")]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: 8, height: 8)
                        .scaleEffect(p.scale)
                        .rotationEffect(.degrees(p.rotation))
                        .position(p.position)
                }
            }
            .onAppear {
                spawnParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }

    func spawnParticles(in size: CGSize) {
        particles = (0..<30).map { _ in
            ConfettiParticle(
                position: CGPoint(x: size.width / 2, y: size.height / 2),
                color: colors.randomElement() ?? .ggAccent,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5),
                velocity: CGPoint(
                    x: CGFloat.random(in: -3...3),
                    y: CGFloat.random(in: -8 ... -2)
                )
            )
        }
    }
}

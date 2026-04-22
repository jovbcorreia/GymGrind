import SwiftUI

// MARK: - Color Palette
extension Color {
    static let ggBackground    = Color(hex: "#0D0D0D")
    static let ggSurface       = Color(hex: "#1A1A1A")
    static let ggSurface2      = Color(hex: "#242424")
    static let ggAccent        = Color(hex: "#FF5C00")  // Electric Orange
    static let ggNeon          = Color(hex: "#B8FF00")  // Neon Green
    static let ggText          = Color(hex: "#F0F0F0")
    static let ggTextSecondary = Color(hex: "#888888")
    static let ggBorder        = Color(hex: "#2E2E2E")
    static let ggDanger        = Color(hex: "#FF3B30")
    static let ggSuccess       = Color(hex: "#B8FF00")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    // Large display numbers
    static let ggDisplayLarge  = Font.system(size: 52, weight: .black, design: .rounded)
    static let ggDisplayMedium = Font.system(size: 36, weight: .black, design: .rounded)
    static let ggDisplaySmall  = Font.system(size: 28, weight: .black, design: .rounded)

    // Headers
    static let ggHeadline      = Font.system(size: 22, weight: .heavy, design: .default)
    static let ggTitle         = Font.system(size: 18, weight: .bold, design: .default)
    static let ggSubtitle      = Font.system(size: 14, weight: .semibold, design: .default)

    // Mono numbers (weights, reps, calories)
    static let ggMono          = Font.system(size: 24, weight: .bold, design: .monospaced)
    static let ggMonoSmall     = Font.system(size: 16, weight: .medium, design: .monospaced)
    static let ggMonoLarge     = Font.system(size: 40, weight: .black, design: .monospaced)

    // Body
    static let ggBody          = Font.system(size: 15, weight: .regular, design: .default)
    static let ggCaption       = Font.system(size: 12, weight: .medium, design: .default)
}

// MARK: - ViewModifiers
struct GGCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.ggSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ggBorder, lineWidth: 1)
            )
    }
}

struct GGButtonStyle: ButtonStyle {
    var color: Color = .ggAccent
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ggTitle)
            .foregroundColor(.black)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .padding(.horizontal, fullWidth ? 0 : 24)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1.0))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GGSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ggTitle)
            .foregroundColor(.ggAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.ggSurface2)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.ggAccent.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func ggCard() -> some View { modifier(GGCardStyle()) }

    func ggSectionHeader(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.ggCaption)
                .foregroundColor(.ggTextSecondary)
                .tracking(1.5)
                .padding(.bottom, 10)
            self
        }
    }
}

// MARK: - Haptics
struct HapticFeedback {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

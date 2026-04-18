import SwiftUI

// MARK: - Color Palette

/// Islamic-inspired color system: deep emerald base with gold accents
enum SalahColors {
    // Base backgrounds
    static let deepEmerald = Color(hex: "0A1F1A")
    static let darkEmerald = Color(hex: "0F2B23")
    static let emeraldGlow = Color(hex: "1B4D3E")
    static let emeraldMid = Color(hex: "15533E")

    // Accents
    static let tealAccent = Color(hex: "2DD4BF")
    static let tealSoft = Color(hex: "5EEAD4")
    static let goldAccent = Color(hex: "F59E0B")
    static let warmGold = Color(hex: "D4A853")
    static let amberGlow = Color(hex: "FCD34D")

    // Text
    static let pureWhite = Color.white
    static let softWhite = Color(hex: "F3F4F6")
    static let softGray = Color(hex: "9CA3AF")
    static let dimGray = Color(hex: "6B7280")

    // Status
    static let passedPrayer = Color(hex: "4B5563")
    static let activePrayer = Color(hex: "F59E0B")

    // MARK: - Gradients

    static let backgroundGradient = LinearGradient(
        colors: [deepEmerald, darkEmerald],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [emeraldGlow.opacity(0.6), emeraldGlow.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let goldGradient = LinearGradient(
        colors: [goldAccent, warmGold],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let nextPrayerGradient = LinearGradient(
        colors: [emeraldMid.opacity(0.8), emeraldGlow.opacity(0.4)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let headerGradient = LinearGradient(
        colors: [deepEmerald.opacity(0.9), darkEmerald],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Typography

enum SalahTypography {
    static let largeTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let countdown = Font.system(size: 36, weight: .bold, design: .monospaced)
    static let countdownSmall = Font.system(size: 14, weight: .medium, design: .monospaced)
    static let arabic = Font.system(size: 14, weight: .regular, design: .default)
    static let arabicLarge = Font.system(size: 18, weight: .medium, design: .default)
}

// MARK: - Spacing & Layout

enum SalahLayout {
    static let popoverWidth: CGFloat = 320
    static let popoverMaxHeight: CGFloat = 520
    static let cornerRadius: CGFloat = 12
    static let cornerRadiusSmall: CGFloat = 8
    static let cardPadding: CGFloat = 14
    static let sectionSpacing: CGFloat = 12
    static let itemSpacing: CGFloat = 8
    static let iconSize: CGFloat = 20
}

// MARK: - View Modifiers

/// Glassmorphism card effect with emerald tint
struct GlassCard: ViewModifier {
    var cornerRadius: CGFloat = SalahLayout.cornerRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(SalahColors.cardGradient)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                SalahColors.tealAccent.opacity(0.15),
                                lineWidth: 0.5
                            )
                    )
            )
    }
}

/// Gold-highlighted card for the next prayer
struct GoldHighlightCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: SalahLayout.cornerRadius)
                    .fill(SalahColors.nextPrayerGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: SalahLayout.cornerRadius)
                            .strokeBorder(
                                SalahColors.goldAccent.opacity(0.4),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: SalahColors.goldAccent.opacity(0.15),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = SalahLayout.cornerRadius) -> some View {
        modifier(GlassCard(cornerRadius: cornerRadius))
    }

    func goldCard() -> some View {
        modifier(GoldHighlightCard())
    }
}

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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

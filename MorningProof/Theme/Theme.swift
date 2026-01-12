import SwiftUI

// MARK: - Spacing Scale (4pt base)

enum MPSpacing {
    static let xs: CGFloat = 4      // Tight spacing
    static let sm: CGFloat = 8      // Small gaps
    static let md: CGFloat = 12     // Medium spacing
    static let lg: CGFloat = 16     // Default content padding
    static let xl: CGFloat = 20     // Section spacing
    static let xxl: CGFloat = 24    // Card internal spacing
    static let xxxl: CGFloat = 32   // Major section gaps
}

// MARK: - Color Palette (Adaptive Light/Dark)

enum MPColors {
    // Backgrounds
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let surfaceSecondary = Color("SurfaceSecondary")
    static let surfaceHighlight = Color("SurfaceHighlight")

    // Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary = Color("TextTertiary")
    static let textMuted = Color("TextMuted")

    // Brand
    static let primary = Color("Primary")
    static let primaryLight = Color("PrimaryLight")
    static let primaryDark = Color("PrimaryDark")

    // Accent
    static let accent = Color("AccentMain")
    static let accentLight = Color("AccentLight")
    static let accentGold = Color("AccentGold")

    // Semantic
    static let success = Color("Success")
    static let successLight = Color("SuccessLight")
    static let error = Color("Error")
    static let errorLight = Color("ErrorLight")
    static let warning = Color("Warning")
    static let warningLight = Color("WarningLight")

    // UI Elements
    static let border = Color("Border")
    static let divider = Color("Divider")
    static let progressBg = Color("ProgressBg")

    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let accentGradient = LinearGradient(
        colors: [accent, accentGold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography

enum MPFont {
    // Display - Large numbers, hero text
    static func displayLarge() -> Font { .system(size: 48, weight: .bold, design: .rounded) }
    static func displayMedium() -> Font { .system(size: 42, weight: .bold, design: .rounded) }
    static func displaySmall() -> Font { .system(size: 36, weight: .bold, design: .rounded) }

    // Headings
    static func headingLarge() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func headingMedium() -> Font { .title2.bold() }
    static func headingSmall() -> Font { .title3.weight(.semibold) }

    // Body
    static func bodyLarge() -> Font { .body }
    static func bodyMedium() -> Font { .subheadline }
    static func bodySmall() -> Font { .caption }

    // Labels
    static func labelLarge() -> Font { .headline }
    static func labelMedium() -> Font { .subheadline.weight(.medium) }
    static func labelSmall() -> Font { .caption.weight(.medium) }
    static func labelTiny() -> Font { .caption2 }
}

// MARK: - Corner Radius

enum MPRadius {
    static let xs: CGFloat = 4      // Tiny badges
    static let sm: CGFloat = 8      // Small buttons, badges
    static let md: CGFloat = 12     // Inputs, medium elements
    static let lg: CGFloat = 16     // Cards, large buttons
    static let xl: CGFloat = 20     // Hero cards, modals
    static let full: CGFloat = 100  // Circular/pill
}

// MARK: - Shadows

enum MPShadow {
    case small
    case medium
    case large

    var radius: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 10
        case .large: return 16
        }
    }

    var y: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        }
    }

    var opacity: Double {
        switch self {
        case .small: return 0.08
        case .medium: return 0.10
        case .large: return 0.12
        }
    }

    var color: Color {
        Color.black.opacity(opacity)
    }
}

// MARK: - Icon Sizes

enum MPIconSize {
    static let sm: CGFloat = 16     // Inline icons
    static let md: CGFloat = 20     // List icons
    static let lg: CGFloat = 24     // Prominent icons
    static let xl: CGFloat = 32     // Feature icons
    static let xxl: CGFloat = 44    // Card icons
    static let hero: CGFloat = 60   // Main display
}

// MARK: - Button Heights

enum MPButtonHeight {
    static let sm: CGFloat = 36     // Compact
    static let md: CGFloat = 44     // Standard
    static let lg: CGFloat = 52     // Primary CTA
}

// MARK: - View Modifiers

extension View {
    func mpShadow(_ size: MPShadow = .medium) -> some View {
        self.shadow(color: size.color, radius: size.radius, x: 0, y: size.y)
    }

    func mpCard(padding: CGFloat = MPSpacing.lg, radius: CGFloat = MPRadius.lg, shadow: MPShadow = .medium) -> some View {
        self
            .padding(padding)
            .background(MPColors.surface)
            .cornerRadius(radius)
            .mpShadow(shadow)
    }
}

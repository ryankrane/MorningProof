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

// MARK: - Color Palette

enum MPColors {
    // Backgrounds
    static let background = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let surface = Color.white
    static let surfaceSecondary = Color(red: 0.95, green: 0.93, blue: 0.9)
    static let surfaceHighlight = Color(red: 1.0, green: 0.97, blue: 0.92)

    // Text
    static let textPrimary = Color(red: 0.35, green: 0.28, blue: 0.22)
    static let textSecondary = Color(red: 0.5, green: 0.45, blue: 0.4)
    static let textTertiary = Color(red: 0.6, green: 0.5, blue: 0.4)
    static let textMuted = Color(red: 0.7, green: 0.65, blue: 0.6)

    // Brand
    static let primary = Color(red: 0.55, green: 0.45, blue: 0.35)
    static let primaryLight = Color(red: 0.75, green: 0.65, blue: 0.55)
    static let primaryDark = Color(red: 0.45, green: 0.35, blue: 0.28)

    // Accent
    static let accent = Color(red: 0.9, green: 0.6, blue: 0.35)
    static let accentLight = Color(red: 0.95, green: 0.9, blue: 0.85)
    static let accentGold = Color(red: 0.85, green: 0.65, blue: 0.2)

    // Semantic
    static let success = Color(red: 0.55, green: 0.75, blue: 0.55)
    static let successLight = Color(red: 0.9, green: 0.97, blue: 0.9)
    static let error = Color(red: 0.85, green: 0.55, blue: 0.5)
    static let errorLight = Color(red: 0.98, green: 0.93, blue: 0.92)
    static let warning = Color(red: 0.95, green: 0.75, blue: 0.4)

    // UI Elements
    static let border = Color(red: 0.8, green: 0.75, blue: 0.7)
    static let divider = Color(red: 0.92, green: 0.9, blue: 0.87)
    static let progressBg = Color(red: 0.92, green: 0.9, blue: 0.87)

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
        case .small: return 0.04
        case .medium: return 0.05
        case .large: return 0.06
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

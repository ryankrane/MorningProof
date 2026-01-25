import SwiftUI

struct MPButton: View {
    let title: String
    let style: MPButtonStyle
    var icon: String?
    var iconPosition: MPIconPosition
    var isLoading: Bool
    var isDisabled: Bool
    var size: MPButtonSize
    let action: () -> Void

    init(
        title: String,
        style: MPButtonStyle,
        icon: String? = nil,
        iconPosition: MPIconPosition = .leading,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        size: MPButtonSize = .large,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.iconPosition = iconPosition
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.size = size
        self.action = action
    }

    enum MPIconPosition {
        case leading
        case trailing
    }

    enum MPButtonStyle {
        case primary
        case dark      // Black button with white text (paywall style)
        case secondary
        case tertiary
        case destructive
    }

    enum MPButtonSize {
        case small
        case medium
        case large

        var height: CGFloat {
            switch self {
            case .small: return MPButtonHeight.sm
            case .medium: return MPButtonHeight.md
            case .large: return MPButtonHeight.lg
            }
        }

        var font: Font {
            switch self {
            case .small: return MPFont.labelSmall()
            case .medium: return MPFont.labelMedium()
            case .large: return MPFont.labelLarge()
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: MPSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(foregroundColor)
                } else {
                    if let icon = icon, iconPosition == .leading {
                        Image(systemName: icon)
                            .font(.system(size: iconSize))
                    }
                    Text(title)
                        .font(size.font)
                        .contentTransition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: title)
                    if let icon = icon, iconPosition == .trailing {
                        Image(systemName: icon)
                            .font(.system(size: iconSize))
                    }
                }
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .background(backgroundColor)
            .cornerRadius(MPRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: MPRadius.lg)
                    .stroke(borderColor, lineWidth: style == .secondary ? 1.5 : 0)
            )
            .shadow(
                color: (style == .primary || style == .dark) ? Color.black.opacity(0.15) : Color.clear,
                radius: (style == .primary || style == .dark) ? 8 : 0,
                y: (style == .primary || style == .dark) ? 4 : 0
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1)
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: return MPIconSize.sm
        case .medium: return MPIconSize.md
        case .large: return MPIconSize.md
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .dark: return .white
        case .secondary: return MPColors.primary
        case .tertiary: return MPColors.textSecondary
        case .destructive: return MPColors.error
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return MPColors.primary
        case .dark: return MPColors.textPrimary
        case .secondary: return MPColors.surface
        case .tertiary: return Color.clear
        case .destructive: return MPColors.surface
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return Color.clear
        case .dark: return Color.clear
        case .secondary: return MPColors.border
        case .tertiary: return Color.clear
        case .destructive: return MPColors.error.opacity(0.3)
        }
    }
}

// MARK: - Icon Button

struct MPIconButton: View {
    let icon: String
    var size: CGFloat
    var bgColor: Color
    var iconColor: Color
    let action: () -> Void

    init(
        icon: String,
        size: CGFloat = MPIconSize.lg,
        backgroundColor: Color = MPColors.surface,
        iconColor: Color = MPColors.textSecondary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.bgColor = backgroundColor
        self.iconColor = iconColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(bgColor)
                    .frame(width: size + MPSpacing.lg, height: size + MPSpacing.lg)
                    .shadow(color: MPShadow.small.color, radius: MPShadow.small.radius, x: 0, y: MPShadow.small.y)

                Image(systemName: icon)
                    .font(.system(size: size * 0.5))
                    .foregroundColor(iconColor)
            }
        }
    }
}

#Preview {
    VStack(spacing: MPSpacing.lg) {
        MPButton(title: "Primary Button", style: .primary) { }

        MPButton(title: "Secondary Button", style: .secondary) { }

        MPButton(title: "Tertiary Button", style: .tertiary) { }

        MPButton(title: "Delete", style: .destructive, icon: "trash") { }

        MPButton(title: "Loading...", style: .primary, isLoading: true) { }

        HStack(spacing: MPSpacing.md) {
            MPIconButton(icon: "gear") { }
            MPIconButton(icon: "camera.fill", backgroundColor: MPColors.primary, iconColor: .white) { }
        }
    }
    .padding(MPSpacing.xl)
    .background(MPColors.background)
}

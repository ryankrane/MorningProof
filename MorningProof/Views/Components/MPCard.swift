import SwiftUI

struct MPCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var radius: CGFloat
    var shadowSize: MPShadow

    init(
        padding: CGFloat = MPSpacing.lg,
        radius: CGFloat = MPRadius.lg,
        shadowSize: MPShadow = .medium,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.radius = radius
        self.shadowSize = shadowSize
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(MPColors.surface)
            .cornerRadius(radius)
            .shadow(color: shadowSize.color, radius: shadowSize.radius, x: 0, y: shadowSize.y)
    }
}

// MARK: - Hero Card Variant

struct MPHeroCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(MPSpacing.xl)
            .background(MPColors.surface)
            .cornerRadius(MPRadius.xl)
            .shadow(color: MPShadow.large.color, radius: MPShadow.large.radius, x: 0, y: MPShadow.large.y)
    }
}

// MARK: - Interactive Card

struct MPInteractiveCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    var padding: CGFloat
    var radius: CGFloat

    init(
        padding: CGFloat = MPSpacing.lg,
        radius: CGFloat = MPRadius.lg,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.radius = radius
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(padding)
                .background(MPColors.surface)
                .cornerRadius(radius)
                .shadow(color: MPShadow.medium.color, radius: MPShadow.medium.radius, x: 0, y: MPShadow.medium.y)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: MPSpacing.xl) {
        MPCard {
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                Text("Standard Card")
                    .font(MPFont.labelLarge())
                    .foregroundColor(MPColors.textPrimary)
                Text("This is a standard card with medium shadow")
                    .font(MPFont.bodySmall())
                    .foregroundColor(MPColors.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        MPHeroCard {
            VStack(spacing: MPSpacing.md) {
                Text("Hero Card")
                    .font(MPFont.headingMedium())
                    .foregroundColor(MPColors.textPrimary)
                Text("Larger padding and shadow")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }
        }
    }
    .padding(MPSpacing.xl)
    .background(MPColors.background)
}

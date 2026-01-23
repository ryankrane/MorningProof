import SwiftUI

/// A brief toast that appears after completing an honor system habit,
/// allowing the user to undo accidental completions.
struct UndoToastView: View {
    let habitName: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            // Checkmark icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(MPColors.success)

            // Text
            Text("\(habitName) completed")
                .font(MPFont.labelMedium())
                .foregroundColor(MPColors.textPrimary)
                .lineLimit(1)

            Spacer()

            // Undo button
            Button(action: {
                HapticManager.shared.mediumTap()
                onUndo()
            }) {
                Text("Undo")
                    .font(MPFont.labelMedium())
                    .foregroundColor(MPColors.primary)
                    .padding(.horizontal, MPSpacing.md)
                    .padding(.vertical, MPSpacing.sm)
                    .background(MPColors.primary.opacity(0.15))
                    .cornerRadius(MPRadius.sm)
            }

            // Dismiss button
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(MPColors.textTertiary)
            }
        }
        .padding(.horizontal, MPSpacing.lg)
        .padding(.vertical, MPSpacing.md)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.medium)
        .padding(.horizontal, MPSpacing.xl)
    }
}

#Preview {
    VStack {
        Spacer()
        UndoToastView(
            habitName: "Cold Shower",
            onUndo: { print("Undo tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
        .padding(.bottom, 50)
    }
    .background(MPColors.background)
}

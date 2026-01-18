import SwiftUI

// MARK: - Distraction Model

struct DistractionType: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color

    static let allDistractions: [DistractionType] = [
        DistractionType(name: "Instagram", icon: "camera.fill", color: Color(red: 0.88, green: 0.19, blue: 0.42)),
        DistractionType(name: "TikTok", icon: "play.square.fill", color: .black),
        DistractionType(name: "Twitter/X", icon: "bubble.left.fill", color: Color(red: 0.11, green: 0.63, blue: 0.95)),
        DistractionType(name: "YouTube", icon: "play.rectangle.fill", color: .red),
        DistractionType(name: "Reddit", icon: "text.bubble.fill", color: Color(red: 1.0, green: 0.27, blue: 0.0)),
        DistractionType(name: "Snapchat", icon: "camera.viewfinder", color: Color(red: 1.0, green: 0.92, blue: 0.0)),
        DistractionType(name: "Facebook", icon: "person.2.fill", color: Color(red: 0.26, green: 0.40, blue: 0.70)),
        DistractionType(name: "Gaming", icon: "gamecontroller.fill", color: Color(red: 0.55, green: 0.24, blue: 0.78)),
        DistractionType(name: "Netflix", icon: "tv.fill", color: Color(red: 0.90, green: 0.07, blue: 0.13)),
        DistractionType(name: "Email", icon: "envelope.fill", color: Color(red: 0.20, green: 0.60, blue: 0.86)),
        DistractionType(name: "News", icon: "newspaper.fill", color: Color(red: 0.35, green: 0.35, blue: 0.35)),
        DistractionType(name: "Other", icon: "ellipsis.circle.fill", color: MPColors.textSecondary),
    ]
}

// MARK: - Distraction Card

struct DistractionCard: View {
    let distraction: DistractionType
    let isSelected: Bool
    let onTap: () -> Void

    @State private var lockScale: CGFloat = 0
    @State private var lockRotation: Double = -30

    var body: some View {
        Button(action: {
            if !isSelected {
                // Heavy THUD haptic when locking an app
                HapticManager.shared.heavyTap()
            } else {
                // Light haptic when unlocking
                HapticManager.shared.light()
            }
            onTap()
        }) {
            ZStack {
                // Base card
                VStack(spacing: MPSpacing.sm) {
                    // App icon
                    ZStack {
                        Circle()
                            .fill(distraction.color.opacity(isSelected ? 0.2 : 1.0))
                            .frame(width: 56, height: 56)

                        Image(systemName: distraction.icon)
                            .font(.system(size: 24))
                            .foregroundColor(isSelected ? distraction.color.opacity(0.5) : .white)
                    }
                    .saturation(isSelected ? 0 : 1) // Grayscale when selected

                    Text(distraction.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? MPColors.textTertiary : MPColors.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(
                    RoundedRectangle(cornerRadius: MPRadius.lg)
                        .fill(MPColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MPRadius.lg)
                        .stroke(isSelected ? Color.red.opacity(0.6) : Color.clear, lineWidth: 2.5)
                )
                .overlay(
                    // Red tint overlay when jailed
                    RoundedRectangle(cornerRadius: MPRadius.lg)
                        .fill(Color.red.opacity(isSelected ? 0.08 : 0))
                )
                .saturation(isSelected ? 0.3 : 1) // Desaturate entire card

                // Lock icon overlay
                if isSelected {
                    ZStack {
                        // Lock background glow
                        Circle()
                            .fill(Color.red.opacity(0.9))
                            .frame(width: 36, height: 36)
                            .shadow(color: .red.opacity(0.5), radius: 8, x: 0, y: 2)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(lockScale)
                    .rotationEffect(.degrees(lockRotation))
                    .offset(y: -8) // Center on the icon
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                // Animate lock slamming down
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5, blendDuration: 0)) {
                    lockScale = 1.0
                    lockRotation = 0
                }
            } else {
                // Reset lock animation
                lockScale = 0
                lockRotation = -30
            }
        }
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Distraction Selection View

struct DistractionSelectionView: View {
    let onContinue: (Set<DistractionType>) -> Void

    @State private var selectedDistractions: Set<DistractionType> = []
    @State private var hasAppeared = false

    private let columns = [
        GridItem(.flexible(), spacing: MPSpacing.md),
        GridItem(.flexible(), spacing: MPSpacing.md),
        GridItem(.flexible(), spacing: MPSpacing.md)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: MPSpacing.xxl) {
                    // Header
                    VStack(spacing: MPSpacing.md) {
                        Text("Lock your biggest time-wasters")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(MPColors.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Choose the apps that steal your mornings.\nThey stay locked until your habits are done.")
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                    }
                    .padding(.top, MPSpacing.xl)
                    .padding(.horizontal, MPSpacing.lg)

                    // Grid of distraction cards
                    LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                        ForEach(DistractionType.allDistractions) { distraction in
                            DistractionCard(
                                distraction: distraction,
                                isSelected: selectedDistractions.contains(distraction)
                            ) {
                                toggleSelection(distraction)
                            }
                        }
                    }
                    .padding(.horizontal, MPSpacing.lg)

                    // Bottom spacer for sticky button
                    Spacer()
                        .frame(height: 100)
                }
            }

            // Sticky bottom button
            VStack(spacing: 0) {
                // Fade gradient at top
                LinearGradient(
                    colors: [MPColors.background.opacity(0), MPColors.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                VStack(spacing: MPSpacing.md) {
                    if selectedDistractions.isEmpty {
                        // Ghost button state
                        Button(action: {
                            HapticManager.shared.light()
                            onContinue(selectedDistractions)
                        }) {
                            Text("I have no distractions")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(MPColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: MPButtonHeight.lg)
                                .background(
                                    RoundedRectangle(cornerRadius: MPRadius.lg)
                                        .stroke(MPColors.border, lineWidth: 1.5)
                                )
                        }
                    } else {
                        // Active state with count
                        Button(action: {
                            HapticManager.shared.medium()
                            onContinue(selectedDistractions)
                        }) {
                            HStack(spacing: MPSpacing.sm) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 16, weight: .semibold))

                                Text("Lock \(selectedDistractions.count) App\(selectedDistractions.count == 1 ? "" : "s") & Save My Morning")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: MPButtonHeight.lg)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.35, blue: 0.15),
                                        Color(red: 0.95, green: 0.20, blue: 0.10)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(MPRadius.lg)
                            .shadow(color: Color.red.opacity(0.35), radius: 12, x: 0, y: 6)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, MPSpacing.xl)
                .padding(.bottom, MPSpacing.xxl)
                .background(MPColors.background)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedDistractions.isEmpty)
            }
        }
        .background(MPColors.background)
    }

    private func toggleSelection(_ distraction: DistractionType) {
        if selectedDistractions.contains(distraction) {
            selectedDistractions.remove(distraction)
        } else {
            selectedDistractions.insert(distraction)
        }
    }
}

// MARK: - Preview

#Preview {
    DistractionSelectionView { selections in
        print("Selected: \(selections.map { $0.name })")
    }
    .preferredColorScheme(.dark)
}

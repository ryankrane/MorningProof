import SwiftUI

// MARK: - Distraction Selection View (Family Controls)
// Uses Apple's FamilyActivitySelection picker to show real app icons

#if true

import FamilyControls

struct DistractionSelectionView: View {
    let onContinue: (FamilyActivitySelection) -> Void

    // View state enum for transitioning between intro and app picker
    enum ViewState {
        case intro           // Show feature cards + authorization button
        case selectingApps   // Show inline FamilyActivityPicker
    }

    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var selection = FamilyActivitySelection()
    @State private var viewState: ViewState = .intro
    @State private var showContent = false
    @State private var showCards = [false, false, false]
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            // Header section (condensed in selectingApps state)
            headerSection
                .padding(.top, viewState == .selectingApps ? MPSpacing.md : 0)

            // Main content switches based on state
            Group {
                switch viewState {
                case .intro:
                    introContent
                case .selectingApps:
                    appPickerContent
                }
            }
            .id(viewState) // Forces clean view replacement (avoids animation overlap)

            // Bottom buttons
            bottomButtons
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            // Check if already authorized and skip to picker
            if screenTimeManager.isAuthorized {
                viewState = .selectingApps
                showContent = true
            } else {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
                for i in 0..<3 {
                    withAnimation(.easeOut(duration: 0.4).delay(0.3 + Double(i) * 0.12)) {
                        showCards[i] = true
                    }
                }
            }
            // Load any previously selected apps
            selection = screenTimeManager.selectedApps
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: MPSpacing.sm) {
            ZStack {
                // Animated glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.red.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: viewState == .selectingApps ? 40 : 50
                        )
                    )
                    .frame(width: viewState == .selectingApps ? 80 : 100,
                           height: viewState == .selectingApps ? 80 : 100)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.35, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: viewState == .selectingApps ? 56 : 72,
                           height: viewState == .selectingApps ? 56 : 72)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: viewState == .selectingApps ? 24 : 32, weight: .semibold))
                    .foregroundColor(.white)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)

            Text(viewState == .selectingApps ? "Select Apps to Block" : "Lock Your Time-Wasters")
                .font(.system(size: viewState == .selectingApps ? 22 : 28, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)

            if viewState == .intro {
                Text("Choose apps to block until your\nmorning habits are complete")
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 15)
        .animation(.easeInOut(duration: 0.3), value: viewState)
    }

    // MARK: - Intro Content (Feature Cards)

    @ViewBuilder
    private var introContent: some View {
        VStack(spacing: MPSpacing.xxl) {
            Spacer()

            // Feature cards
            VStack(spacing: MPSpacing.md) {
                DistractionFeatureRow(
                    icon: "app.badge.fill",
                    title: "Your Real Apps",
                    description: "Select from apps actually on your phone",
                    color: MPColors.primary,
                    isVisible: showCards[0]
                )

                DistractionFeatureRow(
                    icon: "sunrise.fill",
                    title: "Morning Only",
                    description: "Apps unlock once you complete habits",
                    color: Color(red: 1.0, green: 0.6, blue: 0.3),
                    isVisible: showCards[1]
                )

                DistractionFeatureRow(
                    icon: "hand.raised.fill",
                    title: "You're In Control",
                    description: "Change selections anytime in Settings",
                    color: MPColors.success,
                    isVisible: showCards[2]
                )
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()
        }
    }

    // MARK: - App Picker Content (Inline Picker)

    @ViewBuilder
    private var appPickerContent: some View {
        VStack(spacing: MPSpacing.md) {
            // Selected count badge
            if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
                let count = selection.applicationTokens.count + selection.categoryTokens.count
                HStack(spacing: MPSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MPColors.success)
                    Text("\(count) app\(count == 1 ? "" : "s")/categor\(count == 1 ? "y" : "ies") selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MPColors.success)
                }
                .padding(.top, MPSpacing.sm)
                .transition(.scale.combined(with: .opacity))
            }

            // Inline FamilyActivityPicker
            FamilyActivityPicker(selection: $selection)
                .padding(.horizontal, MPSpacing.md)
        }
    }

    // MARK: - Bottom Buttons

    @ViewBuilder
    private var bottomButtons: some View {
        VStack(spacing: MPSpacing.md) {
            // Authorization button (only in intro state when not authorized)
            if viewState == .intro && !screenTimeManager.isAuthorized {
                Button {
                    requestAuthorization()
                } label: {
                    HStack(spacing: MPSpacing.sm) {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text(isRequesting ? "Connecting..." : "Connect Screen Time")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: MPButtonHeight.lg)
                    .background(MPColors.primary)
                    .cornerRadius(MPRadius.lg)
                }
                .disabled(isRequesting)
            }

            // Continue/Skip button
            Button {
                screenTimeManager.saveSelectedApps(selection)
                onContinue(selection)
            } label: {
                if viewState == .selectingApps {
                    // Full button style when in picker mode
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty
                              ? "arrow.right" : "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text(selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty
                             ? "Skip for now"
                             : "Continue")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: MPButtonHeight.lg)
                    .background {
                        if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
                            MPColors.textTertiary
                        } else {
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.35, blue: 0.2), Color(red: 0.9, green: 0.2, blue: 0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                    }
                    .cornerRadius(MPRadius.lg)
                    .shadow(color: selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty
                            ? .clear : Color.red.opacity(0.3), radius: 10, x: 0, y: 4)
                } else {
                    // Text-only style in intro mode
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, MPSpacing.xxxl)
        .padding(.bottom, 50)
        .animation(.easeInOut(duration: 0.3), value: viewState)
        .animation(.easeInOut(duration: 0.2), value: selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty)
    }

    // MARK: - Authorization

    private func requestAuthorization() {
        isRequesting = true
        Task {
            do {
                try await screenTimeManager.requestAuthorization()
                await MainActor.run {
                    isRequesting = false
                    if screenTimeManager.isAuthorized {
                        // Transition to inline picker after authorization
                        withAnimation(.easeInOut(duration: 0.4)) {
                            viewState = .selectingApps
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                }
            }
        }
    }
}

private struct DistractionFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isVisible: Bool

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textSecondary)
            }

            Spacer()
        }
        .padding(MPSpacing.md)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -20)
    }
}

#else

// MARK: - FALLBACK VERSION (SF Symbols - No Family Controls)
// This legacy fallback uses SF Symbols instead of real app icons.
// Only compiles when Family Controls is disabled (change #if true to #if false above).

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
    let index: Int
    let onTap: () -> Void

    @State private var lockScale: CGFloat = 0
    @State private var lockRotation: Double = -30
    @State private var floatOffset: CGFloat = 0
    @State private var glowScale: CGFloat = 1.0
    @State private var isVisible = false

    // Each card gets a unique float timing
    private var floatDuration: Double {
        2.0 + Double(index % 4) * 0.3
    }

    private var floatDelay: Double {
        Double(index) * 0.1
    }

    var body: some View {
        Button(action: {
            if !isSelected {
                HapticManager.shared.heavyTap()
            } else {
                HapticManager.shared.light()
            }
            onTap()
        }) {
            ZStack {
                // Base card
                VStack(spacing: MPSpacing.sm) {
                    // App icon with glow and float
                    ZStack {
                        // Glow behind icon
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [distraction.color.opacity(0.5), distraction.color.opacity(0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 70, height: 70)
                            .scaleEffect(glowScale)
                            .opacity(isSelected ? 0 : 0.6)

                        // Main icon circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isSelected
                                        ? [distraction.color.opacity(0.2), distraction.color.opacity(0.1)]
                                        : [distraction.color, distraction.color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: isSelected ? .clear : distraction.color.opacity(0.4), radius: 8, x: 0, y: 4)

                        Image(systemName: distraction.icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(isSelected ? distraction.color.opacity(0.4) : .white)
                    }
                    .offset(y: isSelected ? 0 : floatOffset)
                    .saturation(isSelected ? 0.3 : 1)

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
                        .overlay(
                            // Subtle gradient border when not selected
                            RoundedRectangle(cornerRadius: MPRadius.lg)
                                .stroke(
                                    LinearGradient(
                                        colors: isSelected
                                            ? [Color.red.opacity(0.6), Color.red.opacity(0.3)]
                                            : [distraction.color.opacity(0.2), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
                .overlay(
                    // Red tint overlay when jailed
                    RoundedRectangle(cornerRadius: MPRadius.lg)
                        .fill(Color.red.opacity(isSelected ? 0.1 : 0))
                )

                // Lock icon overlay
                if isSelected {
                    ZStack {
                        // Lock background glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.red, Color.red.opacity(0.8)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: .red.opacity(0.6), radius: 10, x: 0, y: 2)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(lockScale)
                    .rotationEffect(.degrees(lockRotation))
                    .offset(y: -8)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            // Staggered entrance
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3 + Double(index) * 0.05)) {
                isVisible = true
            }

            // Start floating animation
            DispatchQueue.main.asyncAfter(deadline: .now() + floatDelay + 0.5) {
                withAnimation(.easeInOut(duration: floatDuration).repeatForever(autoreverses: true)) {
                    floatOffset = -6
                }
            }

            // Start glow pulse
            DispatchQueue.main.asyncAfter(deadline: .now() + floatDelay + 0.3) {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowScale = 1.15
                }
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5, blendDuration: 0)) {
                    lockScale = 1.0
                    lockRotation = 0
                }
            } else {
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
    @State private var showHeader = false
    @State private var showSubtext = false

    // Locking animation states
    @State private var isLocking = false
    @State private var lockingApps: [DistractionType] = []
    @State private var currentLockIndex = 0
    @State private var showLockComplete = false
    @State private var shieldScale: CGFloat = 0.5
    @State private var shieldOpacity: Double = 0
    @State private var lockPulse: CGFloat = 1.0

    private let columns = [
        GridItem(.flexible(), spacing: MPSpacing.md),
        GridItem(.flexible(), spacing: MPSpacing.md),
        GridItem(.flexible(), spacing: MPSpacing.md)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MPSpacing.xxl) {
                    // Header with animation
                    VStack(spacing: MPSpacing.md) {
                        Text("Lock your biggest time-wasters")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(MPColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .opacity(showHeader ? 1 : 0)
                            .offset(y: showHeader ? 0 : 15)

                        Text("Choose the apps that steal your mornings.\nThey stay locked until your habits are done.")
                            .font(.system(size: 15))
                            .foregroundColor(MPColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .opacity(showSubtext ? 1 : 0)
                            .offset(y: showSubtext ? 0 : 10)
                    }
                    .padding(.top, MPSpacing.xl)
                    .padding(.horizontal, MPSpacing.lg)

                    // Grid of distraction cards
                    LazyVGrid(columns: columns, spacing: MPSpacing.md) {
                        ForEach(Array(DistractionType.allDistractions.enumerated()), id: \.element.id) { index, distraction in
                            DistractionCard(
                                distraction: distraction,
                                isSelected: selectedDistractions.contains(distraction),
                                index: index
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
                            Text("I'll set this up later")
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
                            startLockingAnimation()
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
        .overlay {
            // Locking animation overlay
            if isLocking {
                LockingOverlayView(
                    apps: lockingApps,
                    currentIndex: currentLockIndex,
                    showComplete: showLockComplete,
                    shieldScale: shieldScale,
                    shieldOpacity: shieldOpacity,
                    lockPulse: lockPulse
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showHeader = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) {
                showSubtext = true
            }
        }
    }

    private func toggleSelection(_ distraction: DistractionType) {
        if selectedDistractions.contains(distraction) {
            selectedDistractions.remove(distraction)
        } else {
            selectedDistractions.insert(distraction)
        }
    }

    private func startLockingAnimation() {
        // Prepare the apps list
        lockingApps = Array(selectedDistractions)
        currentLockIndex = 0
        showLockComplete = false
        shieldScale = 0.5
        shieldOpacity = 0
        lockPulse = 1.0

        // Show the overlay
        withAnimation(.easeOut(duration: 0.3)) {
            isLocking = true
            shieldOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            shieldScale = 1.0
        }

        // Animate through each app
        let delayPerApp = 0.5
        for index in 0..<lockingApps.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4 + Double(index) * delayPerApp) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    currentLockIndex = index + 1
                }
                HapticManager.shared.light()
            }
        }

        // Show completion after all apps locked
        let completionDelay = 0.4 + Double(lockingApps.count) * delayPerApp + 0.3
        DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) {
            HapticManager.shared.success()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showLockComplete = true
            }
            // Pulse the shield
            withAnimation(.easeInOut(duration: 0.3)) {
                lockPulse = 1.15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    lockPulse = 1.0
                }
            }
        }

        // Continue to next screen (pause longer to let user see "Apps Locked!" success state)
        DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay + 1.6) {
            onContinue(selectedDistractions)
        }
    }
}

// MARK: - Locking Overlay View

private struct LockingOverlayView: View {
    let apps: [DistractionType]
    let currentIndex: Int
    let showComplete: Bool
    let shieldScale: CGFloat
    let shieldOpacity: Double
    let lockPulse: CGFloat

    var body: some View {
        ZStack {
            // Background blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Dark overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: MPSpacing.xxl) {
                Spacer()

                // Shield icon with glow
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    showComplete ? Color.green.opacity(0.4) : Color.orange.opacity(0.4),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(lockPulse)

                    // Inner glow ring
                    Circle()
                        .stroke(
                            showComplete ? Color.green.opacity(0.3) : Color.orange.opacity(0.3),
                            lineWidth: 2
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(lockPulse * 1.1)

                    // Shield background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: showComplete
                                    ? [Color(red: 0.2, green: 0.8, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.3)]
                                    : [Color(red: 1.0, green: 0.5, blue: 0.2), Color(red: 0.95, green: 0.3, blue: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: showComplete ? .green.opacity(0.5) : .orange.opacity(0.5), radius: 20, x: 0, y: 8)

                    // Lock/Check icon
                    Image(systemName: showComplete ? "checkmark" : "lock.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .contentTransition(.symbolEffect(.replace))
                }
                .scaleEffect(shieldScale)

                // Status text
                VStack(spacing: MPSpacing.sm) {
                    Text(showComplete ? "Apps Locked!" : "Locking Apps...")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())

                    if !showComplete {
                        Text("\(currentIndex) of \(apps.count)")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // App icons being locked
                if !apps.isEmpty {
                    HStack(spacing: -8) {
                        ForEach(Array(apps.prefix(6).enumerated()), id: \.element.id) { index, app in
                            ZStack {
                                // App icon
                                Circle()
                                    .fill(app.color.opacity(0.2))
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(app.color.opacity(0.4), lineWidth: 1.5)
                                    )

                                Image(systemName: app.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(app.color)

                                // Lock overlay when locked
                                if index < currentIndex {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .zIndex(Double(apps.count - index))
                        }

                        // Show "+X more" if more than 6 apps
                        if apps.count > 6 {
                            Circle()
                                .fill(MPColors.surface)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Text("+\(apps.count - 6)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(MPColors.textSecondary)
                                )
                        }
                    }
                    .padding(.top, MPSpacing.md)
                }

                Spacer()

                // Saving indicator at bottom
                if !showComplete {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.5)))
                            .scaleEffect(0.8)

                        Text("Saving your preferences...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .opacity(shieldOpacity)
    }
}

// MARK: - Preview

#Preview {
    DistractionSelectionView { selections in
        print("Selected: \(selections.map { $0.name })")
    }
    .preferredColorScheme(.dark)
}

#endif // End FALLBACK VERSION

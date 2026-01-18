import SwiftUI

struct StreakHeroCard: View {
    let currentStreak: Int
    let completedToday: Int
    let totalHabits: Int
    let isPerfectMorning: Bool
    let timeUntilCutoff: TimeInterval?  // nil or <= 0 means cutoff has passed
    let cutoffTimeFormatted: String  // e.g. "9:00 AM"
    let hasOverdueHabits: Bool  // True if past cutoff with incomplete habits (that have been completed before)
    @Binding var triggerPulse: Bool  // External trigger for flame pulse (when flying flame arrives)
    @Binding var flameFrame: CGRect  // For lock-in celebration to target the flame
    @Binding var triggerIgnition: Bool  // For 0→1 color transition (gray→vibrant)
    @Binding var impactShake: CGFloat  // For slam shake offset

    @State private var flameScale: CGFloat = 1.0
    @State private var streakNumberScale: CGFloat = 0.8
    @State private var showPerfectBadge = false
    @State private var glowPulse: CGFloat = 0.0
    @State private var arrivalPulse: CGFloat = 1.0  // For the big pulse when flame arrives
    @State private var displayedStreak: Double = 0  // For smooth speedometer-style animation

    // Ignition effect states (0→1 transition)
    @State private var ignitionGlow: CGFloat = 0
    @State private var ignitionScale: CGFloat = 1.0

    // Flare-Up effect states (1+ streak)
    @State private var showFlareUp = false
    @State private var flareScale: CGFloat = 1.0
    @State private var flareOpacity: Double = 0

    // Living flame states (continuous animation after lock-in)
    @State private var livingFlameRotation: Double = 0
    @State private var livingFlameOpacity: Double = 1.0
    @State private var isLivingFlameActive: Bool = false

    // On-fire pulsing flame states (when streak > 0)
    @State private var innerFlameScale: CGFloat = 1.0
    @State private var outerGlowIntensity: CGFloat = 0.0
    @State private var emberOffset: CGFloat = 0

    // Radial flare effect (on flame arrival)
    @State private var radialFlareScale: CGFloat = 0.3
    @State private var radialFlareOpacity: Double = 0

    // Milestone targets
    private let milestones = [7, 14, 21, 30, 60, 90, 180, 365]

    // MARK: - Glow Properties based on streak

    /// Glow radius increases with streak
    var glowRadius: CGFloat {
        guard currentStreak > 0 else { return 0 }
        switch currentStreak {
        case 1...6: return 8
        case 7...13: return 12
        case 14...29: return 16
        default: return 20
        }
    }

    /// Glow opacity increases with streak
    var glowOpacity: CGFloat {
        guard currentStreak > 0 else { return 0 }
        switch currentStreak {
        case 1...6: return 0.4
        case 7...13: return 0.5
        case 14...29: return 0.6
        default: return 0.7
        }
    }

    /// Glow color shifts from orange to gold as streak increases (consistent in dark mode)
    var glowColor: Color {
        guard currentStreak > 0 else { return .clear }
        switch currentStreak {
        case 1...6: return MPColors.flameOrange  // Orange - consistent
        case 7...29: return Color(red: 1.0, green: 0.7, blue: 0.2) // Orange-gold
        default: return Color(red: 1.0, green: 0.84, blue: 0.0) // Pure gold - consistent
        }
    }

    /// Flame icon size scales with streak - Days 1-5 grow each day for early investment feel
    var flameIconSize: CGFloat {
        switch currentStreak {
        case 0: return 40          // Gray flame (no streak)
        case 1: return 44          // Day 1 - just ignited
        case 2: return 48          // Day 2 - growing
        case 3: return 52          // Day 3 - building momentum
        case 4: return 56          // Day 4 - getting strong
        case 5: return 60          // Day 5 - almost a week!
        case 6...13: return 62     // Week territory
        case 14...29: return 66    // Two week+ streak
        default: return 72         // Month+ streak - impressive
        }
    }

    var nextMilestone: Int {
        milestones.first { $0 > currentStreak } ?? 365
    }

    var previousMilestone: Int {
        milestones.last { $0 <= currentStreak } ?? 0
    }

    var progressToNextMilestone: CGFloat {
        let range = nextMilestone - previousMilestone
        let progress = currentStreak - previousMilestone
        return CGFloat(progress) / CGFloat(range)
    }

    /// Formats the countdown interval into a compact string
    /// - >= 1 hour: "3h 45m"
    /// - < 1 hour: "45 min"
    /// - < 1 minute: "45 sec" or "1 second"
    private func compactCountdownText(for interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else if seconds == 1 {
            return "1 second"
        } else {
            return "\(seconds) sec"
        }
    }

    var body: some View {
        VStack(spacing: MPSpacing.lg) {
            // Streak display
            HStack(spacing: MPSpacing.md) {
                // Flame icon with dynamic glow animation
                // Main flame - this determines the layout size
                Image(systemName: currentStreak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: flameIconSize))
                    .foregroundStyle(flameGradient)
                    .scaleEffect(flameScale * arrivalPulse * ignitionScale * innerFlameScale)
                    .rotationEffect(.degrees(livingFlameRotation))
                    .opacity(livingFlameOpacity)
                    // Always-on glow when streak > 0, with pulsing effect
                    .shadow(color: glowColor.opacity(glowOpacity + glowPulse * 0.2 + ignitionGlow * 0.3), radius: glowRadius + glowPulse * 4 + ignitionGlow * 10)
                    .shadow(color: glowColor.opacity(glowOpacity * 0.5 + glowPulse * 0.1), radius: glowRadius * 0.5)
                    // Decorative overlays (don't affect layout)
                    .overlay {
                        // Radial flare (expands on flame arrival)
                        Circle()
                            .stroke(
                                RadialGradient(
                                    colors: [MPColors.flameOrange, MPColors.flameOrange.opacity(0.5), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 50
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(radialFlareScale)
                            .opacity(radialFlareOpacity)
                    }
                    .overlay {
                        // Flare-Up effect: blurred flame pulse behind (for streak 1+)
                        if showFlareUp {
                            Text("🔥")
                                .font(.system(size: MPIconSize.xl * 1.5))
                                .scaleEffect(flareScale)
                                .opacity(flareOpacity)
                                .blur(radius: 8)
                        }
                    }
                    .background {
                        // Ignition glow effect (for 0→1 transition)
                        Circle()
                            .fill(MPColors.flameOrange.opacity(ignitionGlow * 0.6))
                            .frame(width: MPIconSize.xl * 2, height: MPIconSize.xl * 2)
                            .blur(radius: 15)
                            .opacity(ignitionGlow)
                    }
                    .background {
                        // Outer pulsing glow layer (breathing fire effect)
                        if currentStreak > 0 {
                            Image(systemName: "flame.fill")
                                .font(.system(size: flameIconSize * 1.15))
                                .foregroundStyle(MPColors.flameOrange.opacity(0.4))
                                .blur(radius: 6)
                                .scaleEffect(innerFlameScale * 1.1)
                                .opacity(outerGlowIntensity)
                        }
                    }
                    .overlay {
                        // Ember particle floating up (subtle rising heat effect)
                        if currentStreak > 0 {
                            Circle()
                                .fill(MPColors.flameOrange.opacity(0.6))
                                .frame(width: 4, height: 4)
                                .offset(x: 8, y: -flameIconSize * 0.4 - emberOffset)
                                .opacity(Double(1.0 - emberOffset / 20))
                                .blur(radius: 1)
                        }
                    }
                    .offset(x: impactShake) // Apply shake offset from slam impact
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    flameFrame = geo.frame(in: .global)
                                }
                                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                                    flameFrame = newFrame
                                }
                        }
                    )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: MPSpacing.xs) {
                        Text("\(Int(displayedStreak))")
                            .font(MPFont.displayMedium())
                            .foregroundColor(MPColors.textPrimary)
                            .scaleEffect(streakNumberScale)
                            .contentTransition(.numericText())

                        Text("day streak")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textTertiary)
                    }

                    // Progress to next milestone
                    if currentStreak > 0 {
                        HStack(spacing: MPSpacing.sm) {
                            ProgressView(value: progressToNextMilestone)
                                .tint(MPColors.accent)
                                .frame(width: 100)

                            Text("\(nextMilestone) days")
                                .font(MPFont.labelTiny())
                                .foregroundColor(MPColors.textTertiary)
                        }
                    }
                }

                Spacer()
            }

            // Perfect Morning status or progress
            HStack {
                if isPerfectMorning {
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "sparkles")
                            .foregroundColor(MPColors.accentGold)
                        Text("Perfect Morning!")
                            .font(MPFont.labelMedium())
                            .foregroundColor(MPColors.accentGold)
                    }
                    .scaleEffect(showPerfectBadge ? 1.0 : 0.8)
                    .opacity(showPerfectBadge ? 1.0 : 0)
                } else {
                    HStack(spacing: MPSpacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(MPColors.success)
                        Text("\(completedToday)/\(totalHabits) habits completed")
                            .font(MPFont.bodyMedium())
                            .foregroundColor(MPColors.textSecondary)
                    }
                }

                Spacer()

                // Countdown timer - bottom right corner (hide when Perfect Morning achieved)
                if let interval = timeUntilCutoff, interval > 0, !isPerfectMorning {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MPColors.textTertiary)
                        Text(compactCountdownText(for: interval))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MPColors.textTertiary)
                    }
                } else if hasOverdueHabits {
                    // Show LATE badge when past cutoff with incomplete habits
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("LATE")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(MPColors.error)
                }
            }
        }
        .padding(MPSpacing.xl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.xl)
        .mpShadow(.large)
        .onAppear {
            // Speedometer-style sweep animation for streak number
            // Uses easeOut so it accelerates quickly then settles smoothly (like a speedometer needle)
            let duration = min(0.8, 0.3 + Double(currentStreak) * 0.015) // Scales with streak, max 0.8s
            withAnimation(.easeOut(duration: duration)) {
                displayedStreak = Double(currentStreak)
            }

            // Animate streak number scaling in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                streakNumberScale = 1.0
            }

            // Animate flame pulsing (scale)
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                flameScale = 1.1
            }

            // Animate glow pulsing (separate from scale for layered effect)
            if currentStreak > 0 {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPulse = 1.0
                }
                // Start living flame animation immediately for existing streaks
                startLivingFlameAnimation()
                // Start the on-fire pulsing effect
                startOnFireAnimation()
            }

            // Animate perfect badge if applicable
            if isPerfectMorning {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.3)) {
                    showPerfectBadge = true
                }
            }
        }
        .onChange(of: isPerfectMorning) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showPerfectBadge = true
                }
                HapticManager.shared.success()
            }
        }
        .onChange(of: currentStreak) { _, newValue in
            // Animate the streak number when it changes (e.g., after lock-in)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                displayedStreak = Double(newValue)
            }
            // Start fire animation if streak just became > 0
            if newValue > 0 && !isLivingFlameActive {
                startLivingFlameAnimation()
                startOnFireAnimation()
            }
        }
        .onChange(of: triggerPulse) { _, newValue in
            if newValue {
                // Big pulse when the flying flame arrives! (slightly bigger for drama)
                withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                    arrivalPulse = 1.35
                }

                // Radial flare burst - golden ring expands outward
                radialFlareScale = 0.3
                radialFlareOpacity = 0.9
                withAnimation(.easeOut(duration: 0.4)) {
                    radialFlareScale = 2.5
                    radialFlareOpacity = 0
                }

                // Flare-Up effect for streak 1+ (blurred flame pulse behind)
                if currentStreak >= 1 {
                    showFlareUp = true
                    flareScale = 1.0
                    flareOpacity = 0.8

                    withAnimation(.easeOut(duration: 0.25)) {
                        flareScale = 1.8
                        flareOpacity = 0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showFlareUp = false
                    }
                }

                // Return to normal
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        arrivalPulse = 1.0
                    }
                }

                // Start living flame animation after impact settles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startLivingFlameAnimation()
                    startOnFireAnimation()
                }

                // Reset the trigger
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    triggerPulse = false
                }
            }
        }
        .onChange(of: triggerIgnition) { _, newValue in
            if newValue {
                // Ignition effect: 0→1 transition (gray→vibrant with glow + scale pulse)

                // Flash glow intensity to 1.0 over 0.15s
                withAnimation(.easeIn(duration: 0.15)) {
                    ignitionGlow = 1.0
                }

                // Pulse scale to 1.5x with spring
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                    ignitionScale = 1.5
                }

                // Settle back with spring over 0.3s
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        ignitionScale = 1.0
                    }
                }

                // Fade out glow
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        ignitionGlow = 0
                    }
                }

                // Reset the trigger
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    triggerIgnition = false
                }
            }
        }
    }

    var flameGradient: LinearGradient {
        if currentStreak > 0 {
            // Use consistent flame colors that don't change in dark mode
            return MPColors.flameGradient
        } else {
            return LinearGradient(
                colors: [MPColors.textMuted, MPColors.textMuted.opacity(0.5)],
                startPoint: .bottom,
                endPoint: .top
            )
        }
    }

    // MARK: - Living Flame Animation

    /// Starts continuous dynamic animation on the flame to make it feel "alive" and dancing
    private func startLivingFlameAnimation() {
        guard !isLivingFlameActive else { return }
        isLivingFlameActive = true

        // Dancing rotation: ±4 degrees with organic timing - makes flame sway like real fire
        func animateDancingRotation() {
            guard isLivingFlameActive else { return }
            let target = Double.random(in: -4...4)
            let duration = Double.random(in: 0.2...0.5)
            withAnimation(.easeInOut(duration: duration)) {
                livingFlameRotation = target
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                animateDancingRotation()
            }
        }

        // Pulsing opacity: smooth breathing effect instead of flickering
        func animatePulse() {
            guard isLivingFlameActive else { return }
            // Pulse down
            withAnimation(.easeInOut(duration: 0.8)) {
                livingFlameOpacity = 0.85
            }
            // Pulse back up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                guard isLivingFlameActive else { return }
                withAnimation(.easeInOut(duration: 0.8)) {
                    livingFlameOpacity = 1.0
                }
                // Continue the cycle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    animatePulse()
                }
            }
        }

        // Start dancing rotation
        animateDancingRotation()
        // Start pulse with slight offset for organic feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            animatePulse()
        }
    }

    // MARK: - On-Fire Pulsing Animation

    /// Creates a continuous "burning" effect with pulsing scale and glow
    private func startOnFireAnimation() {
        guard currentStreak > 0 else { return }

        // Inner flame pulsing (scale breathing)
        func animateInnerPulse() {
            withAnimation(.easeInOut(duration: 0.6)) {
                innerFlameScale = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    innerFlameScale = 0.95
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animateInnerPulse()
                }
            }
        }

        // Outer glow intensity pulsing (fire breathing)
        func animateOuterGlow() {
            withAnimation(.easeIn(duration: 0.4)) {
                outerGlowIntensity = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.7)) {
                    outerGlowIntensity = 0.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    animateOuterGlow()
                }
            }
        }

        // Ember floating upward animation (continuous loop)
        func animateEmber() {
            emberOffset = 0
            withAnimation(.easeOut(duration: 1.2)) {
                emberOffset = 20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                animateEmber()
            }
        }

        // Start all fire animations with slight offsets for organic feel
        animateInnerPulse()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            animateOuterGlow()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateEmber()
        }
    }
}

#Preview {
    VStack(spacing: MPSpacing.xl) {
        StreakHeroCard(currentStreak: 14, completedToday: 3, totalHabits: 5, isPerfectMorning: false, timeUntilCutoff: 8 * 3600 + 37 * 60, cutoffTimeFormatted: "9:00 AM", hasOverdueHabits: false, triggerPulse: .constant(false), flameFrame: .constant(.zero), triggerIgnition: .constant(false), impactShake: .constant(0))
        StreakHeroCard(currentStreak: 14, completedToday: 5, totalHabits: 5, isPerfectMorning: true, timeUntilCutoff: nil, cutoffTimeFormatted: "9:00 AM", hasOverdueHabits: false, triggerPulse: .constant(false), flameFrame: .constant(.zero), triggerIgnition: .constant(false), impactShake: .constant(0))
        StreakHeroCard(currentStreak: 0, completedToday: 0, totalHabits: 5, isPerfectMorning: false, timeUntilCutoff: 30 * 60, cutoffTimeFormatted: "9:00 AM", hasOverdueHabits: false, triggerPulse: .constant(false), flameFrame: .constant(.zero), triggerIgnition: .constant(false), impactShake: .constant(0))
        // Late state preview
        StreakHeroCard(currentStreak: 5, completedToday: 2, totalHabits: 5, isPerfectMorning: false, timeUntilCutoff: nil, cutoffTimeFormatted: "9:00 AM", hasOverdueHabits: true, triggerPulse: .constant(false), flameFrame: .constant(.zero), triggerIgnition: .constant(false), impactShake: .constant(0))
    }
    .padding()
    .background(MPColors.background)
}

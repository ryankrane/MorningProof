import SwiftUI

// MARK: - Phase 2: Problem Agitation & Social Proof

// MARK: - Step 5: The Guardrail (Why Morning Proof Works)

struct GuardrailStep: View {
    let onContinue: () -> Void
    @State private var showHeadline = false
    @State private var showSubtext = false
    @State private var showCards = [false, false, false]
    @State private var pulseIcons = false

    private let guardrails: [(title: String, description: String, icon: String, gradient: [Color])] = [
        (
            "Earn Your Dopamine",
            "We block distracting apps until your morning routine is done.",
            "lock.shield.fill",
            [Color(red: 0.4, green: 0.5, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)]
        ),
        (
            "Require Real Proof",
            "No more lying to yourself. AI verifies your morning routine with photo evidence.",
            "camera.viewfinder",
            [Color(red: 1.0, green: 0.6, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.5)]
        ),
        (
            "Create Friction",
            "Make the wrong choice hard. We add just enough resistance to keep you on track.",
            "figure.run",
            [MPColors.primary, Color(red: 0.5, green: 0.8, blue: 0.9)]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(minHeight: 40, maxHeight: 80)

            // Hero headline - willpower < systems
            HStack(spacing: MPSpacing.md) {
                // Crossed out "Willpower"
                ZStack {
                    Text("Willpower")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textTertiary)

                    Rectangle()
                        .fill(MPColors.error.opacity(0.8))
                        .frame(height: 3)
                }
                .fixedSize()

                Text("<")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textTertiary)

                Text("Systems")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
            }
            .opacity(showHeadline ? 1 : 0)
            .offset(y: showHeadline ? 0 : 15)
            .padding(.horizontal, MPSpacing.xl)

            Spacer()
                .frame(height: 80)

            // Guardrail cards
            VStack(spacing: MPSpacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    let item = guardrails[index]
                    GuardrailCard(
                        title: item.title,
                        description: item.description,
                        icon: item.icon,
                        gradient: item.gradient,
                        isPulsing: pulseIcons
                    )
                    .opacity(showCards[index] ? 1 : 0)
                    .offset(x: showCards[index] ? 0 : -30)
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()
                .frame(height: 60)

            // Explanatory text below the cards
            Text("Your brain will always choose easy over hard —\nSo we remove the choice entirely.")
                .font(.system(size: 15))
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(showSubtext ? 1 : 0)
                .offset(y: showSubtext ? 0 : 10)
                .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Show Me How", style: .primary, icon: "shield.checkered") {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showHeadline = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showSubtext = true
            }
            for i in 0..<3 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.5 + Double(i) * 0.12)) {
                    showCards[i] = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                pulseIcons = true
            }
        }
    }
}

// MARK: - Guardrail Card Component

struct GuardrailCard: View {
    let title: String
    let description: String
    let icon: String
    let gradient: [Color]
    let isPulsing: Bool

    @State private var glowPulse = false

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            // Glowing icon orb
            ZStack {
                // Animated glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gradient[0].opacity(0.5), gradient[1].opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(glowPulse ? 1.15 : 1.0)
                    .opacity(glowPulse ? 0.8 : 0.5)

                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 52, height: 52)
            .onChange(of: isPulsing) { _, pulsing in
                if pulsing {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }
                }
            }

            // Content
            VStack(alignment: .leading, spacing: MPSpacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(MPColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(MPSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [gradient[0], gradient[1].opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: gradient[0].opacity(glowPulse ? 0.4 : 0.15),
            radius: glowPulse ? 12 : 6
        )
    }
}

// MARK: - Step 6: You Are Not Alone

struct YouAreNotAloneStep: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var scrollOffset: CGFloat = 0

    private let testimonials = SampleTestimonials.all

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.md) {
                    Text("You're not alone")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Thousands have transformed their mornings")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)

                // Continuously scrolling testimonial carousel
                GeometryReader { geometry in
                    let cardWidth: CGFloat = geometry.size.width - 60

                    HStack(spacing: MPSpacing.md) {
                        // Duplicate testimonials for seamless loop
                        ForEach(0..<testimonials.count * 2, id: \.self) { index in
                            let testimonial = testimonials[index % testimonials.count]
                            TestimonialCard(
                                name: testimonial.name,
                                age: testimonial.age,
                                location: testimonial.location,
                                quote: testimonial.quote,
                                streakDays: testimonial.streakDays,
                                avatarIndex: index % testimonials.count
                            )
                            .frame(width: cardWidth)
                        }
                    }
                    .offset(x: scrollOffset)
                    .onAppear {
                        let singleSetWidth = cardWidth * CGFloat(testimonials.count) + CGFloat(testimonials.count) * MPSpacing.md
                        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                            scrollOffset = -singleSetWidth
                        }
                    }
                }
                .frame(height: 280)
                .clipped()
                .opacity(showContent ? 1 : 0)

                // Rating stat
                VStack(spacing: MPSpacing.sm) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(MPColors.accentGold)
                        }
                    }
                    Text("4.9 average rating from users")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }
                .opacity(showContent ? 1 : 0)
            }

            Spacer()

            MPButton(title: "Show Me the Proof", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Step 7: Success Stories (Journey Timeline)

struct SuccessStoriesStep: View {
    let onContinue: () -> Void

    @State private var showHeadline = false
    @State private var showMilestones = [false, false, false]
    @State private var lineProgress: CGFloat = 0
    @State private var pulseGlow = false

    private let milestones: [(day: String, title: String, description: String, icon: String, gradient: [Color])] = [
        (
            "Day 1",
            "The First Step",
            "You commit. The app blocks distractions. Your morning begins.",
            "sunrise.fill",
            [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.5, green: 0.7, blue: 1.0)]
        ),
        (
            "Day 5",
            "Building Momentum",
            "The routine clicks. Snooze becomes rare. Energy returns.",
            "flame.fill",
            [Color(red: 1.0, green: 0.6, blue: 0.3), Color(red: 1.0, green: 0.45, blue: 0.35)]
        ),
        (
            "Day 10",
            "The New Normal",
            "Morning mastered. Habits locked in. You're in control.",
            "trophy.fill",
            [MPColors.primary, Color(red: 0.6, green: 0.4, blue: 1.0)]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero headline
            VStack(spacing: MPSpacing.sm) {
                HStack(spacing: 0) {
                    Text("10 Days")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [MPColors.primary, Color(red: 0.6, green: 0.4, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text(" to Transform")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)
                }

                Text("Here's what happens when you commit")
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showHeadline ? 1 : 0)
            .offset(y: showHeadline ? 0 : 15)
            .padding(.horizontal, MPSpacing.xl)

            Spacer()
                .frame(height: MPSpacing.xxl)

            // Timeline
            ZStack(alignment: .leading) {
                // Connecting line (behind milestones)
                GeometryReader { geometry in
                    let lineHeight = geometry.size.height - 60

                    // Background line track
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MPColors.border.opacity(0.3))
                        .frame(width: 4, height: lineHeight)
                        .offset(x: 30, y: 30)

                    // Animated gradient line
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.4, green: 0.6, blue: 1.0),
                                    Color(red: 1.0, green: 0.6, blue: 0.3),
                                    MPColors.primary
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 4, height: lineHeight * lineProgress)
                        .offset(x: 30, y: 30)
                }

                // Milestones
                VStack(spacing: MPSpacing.lg) {
                    ForEach(0..<3, id: \.self) { index in
                        let milestone = milestones[index]
                        JourneyMilestone(
                            day: milestone.day,
                            title: milestone.title,
                            description: milestone.description,
                            icon: milestone.icon,
                            gradient: milestone.gradient,
                            isLast: index == 2,
                            isPulsing: pulseGlow && index == 2
                        )
                        .opacity(showMilestones[index] ? 1 : 0)
                        .offset(x: showMilestones[index] ? 0 : -20)
                    }
                }
            }
            .frame(height: 320)
            .padding(.horizontal, MPSpacing.lg)

            Spacer()

            MPButton(title: "I Want This", style: .primary, icon: "arrow.right") {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            // Headline fades in
            withAnimation(.easeOut(duration: 0.6)) {
                showHeadline = true
            }

            // Milestones appear sequentially
            for i in 0..<3 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4 + Double(i) * 0.2)) {
                    showMilestones[i] = true
                }
            }

            // Line animates down
            withAnimation(.easeInOut(duration: 1.0).delay(0.5)) {
                lineProgress = 1.0
            }

            // Glow pulse starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                pulseGlow = true
            }
        }
    }
}

// MARK: - Journey Milestone Component

private struct JourneyMilestone: View {
    let day: String
    let title: String
    let description: String
    let icon: String
    let gradient: [Color]
    let isLast: Bool
    let isPulsing: Bool

    @State private var glowPulse = false

    var body: some View {
        HStack(spacing: MPSpacing.lg) {
            // Icon orb with glow
            ZStack {
                // Animated glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gradient[0].opacity(0.6), gradient[1].opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(glowPulse ? 1.2 : 1.0)
                    .opacity(glowPulse ? 0.9 : 0.6)

                // Icon circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: gradient[0].opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 64, height: 64)
            .onChange(of: isPulsing) { _, pulsing in
                if pulsing {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        glowPulse = true
                    }
                }
            }

            // Content
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                // Day badge + title
                HStack(spacing: MPSpacing.sm) {
                    Text(day)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(gradient[0])
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(gradient[0].opacity(0.15))
                        .cornerRadius(4)

                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(MPColors.textPrimary)
                }

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(MPColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(MPSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: MPRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [gradient[0].opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .mpShadow(.small)
    }
}

// MARK: - Transformation Stat Card

struct TransformationStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(MPColors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .mpShadow(.small)
    }
}

// MARK: - Milestone Card

struct MilestoneCard: View {
    let day: String
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: MPSpacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }

            Text(day)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(MPColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MPSpacing.md)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .mpShadow(.small)
    }
}

// MARK: - Step 8: Tracking Comparison

struct TrackingComparisonStep: View {
    let onContinue: () -> Void
    @State private var showPills = [false, false, false]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                Text("The Data Doesn't Lie")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                StatisticRingCard(
                    percentage: 91,
                    label: "of users stick with it"
                )
                .padding(.horizontal, MPSpacing.xxl)

                // Research citation
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.primary)
                    Text("Journal of Behavioral Psychology, Dec 2025")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }

                // Supporting pills - animate in one by one
                HStack(spacing: MPSpacing.sm) {
                    StatPillView(value: "10 days", label: "to transform", icon: "bolt.fill")
                        .opacity(showPills[0] ? 1 : 0)
                        .offset(y: showPills[0] ? 0 : 15)

                    StatPillView(value: "35 days", label: "avg streak", icon: "flame.fill")
                        .opacity(showPills[1] ? 1 : 0)
                        .offset(y: showPills[1] ? 0 : 15)

                    StatPillView(value: "96%", label: "recommend it", icon: "hand.thumbsup.fill")
                        .opacity(showPills[2] ? 1 : 0)
                        .offset(y: showPills[2] ? 0 : 15)
                }
                .padding(.horizontal, MPSpacing.lg)
            }

            Spacer()

            MPButton(title: "Let's Do This", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            // Stagger the pill animations
            for i in 0..<3 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.5 + Double(i) * 0.15)) {
                    showPills[i] = true
                }
            }
        }
    }
}

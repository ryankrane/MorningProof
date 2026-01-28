import SwiftUI

// MARK: - Phase 4: Social Proof (Steps 9-11)

// MARK: - Step 9: You Are Not Alone

struct YouAreNotAloneStep: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var scrollOffset: CGFloat = 0

    private let testimonials = SampleTestimonials.all

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: MPSpacing.md) {
                Text("You're not alone")
                    .padding(.top, 16)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)

                Text("Thousands have transformed their mornings")
                    .font(.system(size: 16))
                    .foregroundColor(MPColors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)

            Spacer()

            VStack(spacing: MPSpacing.xl) {
                // Continuously scrolling testimonial carousel
                GeometryReader { geometry in
                    let cardWidth: CGFloat = geometry.size.width * 0.75

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
                    .offset(x: scrollOffset + (geometry.size.width - cardWidth) / 2)
                    .onAppear {
                        let singleSetWidth = (cardWidth + MPSpacing.md) * CGFloat(testimonials.count)
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

// MARK: - Step 10: Success Stories (Journey Timeline)

struct SuccessStoriesStep: View {
    let onContinue: () -> Void

    @State private var showHeadline = false
    @State private var showMilestones = [false, false, false]
    @State private var lineProgress: CGFloat = 0
    @State private var pulseGlow = false
    @State private var showButton = false

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
            "The routine clicks. Distractions fade. Focus sharpens.",
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
        GeometryReader { geometry in
            VStack(spacing: 0) {
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
                .padding(.top, max(100, geometry.safeAreaInsets.top + 80))

                Spacer()
                    .frame(height: 30)

                // Timeline - flexible height based on screen
                ZStack(alignment: .leading) {
                    // Connecting line (behind milestones)
                    GeometryReader { timelineGeo in
                        let lineHeight = timelineGeo.size.height - 40

                        // Background line track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(MPColors.border.opacity(0.3))
                            .frame(width: 4, height: lineHeight)
                            .offset(x: 30, y: 20)

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
                            .offset(x: 30, y: 20)
                    }

                    // Milestones
                    VStack(spacing: MPSpacing.md) {
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
                            .offset(x: showMilestones[index] ? 0 : -UIScreen.main.bounds.width)
                            .scaleEffect(showMilestones[index] ? 1.0 : 0.95)
                        }
                    }
                }
                .padding(.horizontal, MPSpacing.lg)

                Spacer()
                    .frame(minHeight: 20)

                MPButton(title: "I Want This", style: .primary, icon: "arrow.right", iconPosition: .trailing) {
                    onContinue()
                }
                .padding(.horizontal, MPSpacing.xxxl)
                .padding(.bottom, max(30, geometry.safeAreaInsets.bottom + 20))
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)
                .allowsHitTesting(showButton)
            }
        }
        .onAppear {
            // Headline fades in
            withAnimation(.easeOut(duration: 0.6)) {
                showHeadline = true
            }

            // Milestones slide in one at a time with generous stagger
            for i in 0..<3 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.6 + Double(i) * 0.5)) {
                    showMilestones[i] = true
                }
            }

            // Line animates down (synced with milestone timing)
            withAnimation(.easeInOut(duration: 1.5).delay(0.6)) {
                lineProgress = 1.0
            }

            // Glow pulse and button appear after all milestones have landed
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                pulseGlow = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showButton = true
                }
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
                        .font(.system(size: 11, weight: .bold))
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
        .padding(MPSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MPRadius.lg)
                .fill(MPColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: MPRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [gradient[0].opacity(0.6), gradient[1].opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .mpShadow(.small)
    }
}

// MARK: - Step 11: Tracking Comparison

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

                // Supporting pills - animate in scattered
                HStack(spacing: MPSpacing.sm) {
                    StatPillView(value: "10 days", label: "to transform", icon: "bolt.fill")
                        .opacity(showPills[0] ? 1 : 0)
                        .offset(y: showPills[0] ? 0 : 20)
                        .rotationEffect(.degrees(showPills[0] ? 0 : -5))

                    StatPillView(value: "35 days", label: "avg streak", icon: "flame.fill")
                        .opacity(showPills[1] ? 1 : 0)
                        .offset(y: showPills[1] ? 0 : -15)
                        .rotationEffect(.degrees(showPills[1] ? 0 : 3))

                    StatPillView(value: "96%", label: "recommend it", icon: "hand.thumbsup.fill")
                        .opacity(showPills[2] ? 1 : 0)
                        .offset(y: showPills[2] ? 0 : 25)
                        .rotationEffect(.degrees(showPills[2] ? 0 : -4))
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
            // Stagger the pill animations with scattered timing
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7).delay(1.4)) {
                showPills[1] = true  // Middle first
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65).delay(1.7)) {
                showPills[0] = true  // Left second
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(2.0)) {
                showPills[2] = true  // Right last
            }
        }
    }
}

// MARK: - Transformation Stat Card (Helper)

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

// MARK: - Milestone Card (Helper)

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

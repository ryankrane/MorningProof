import SwiftUI

// MARK: - Phase 2: Problem Agitation & Social Proof

// MARK: - Step 5: The Guardrail (Why Morning Proof Works)

struct GuardrailStep: View {
    let onContinue: () -> Void
    @State private var showHeadline = false
    @State private var showCards = [false, false, false]

    private let frictionCards: [(title: String, tagline: String, description: String, icon: String, color: Color)] = [
        (
            "The Dopamine Gate",
            "Earned Access",
            "You shouldn't get a 'win' (scrolling) before you've even moved. We gate your distractions until you've actually earned them.",
            "lock.shield.fill",
            Color(red: 0.4, green: 0.6, blue: 1.0) // Blue
        ),
        (
            "The Proof Gap",
            "Hard Evidence",
            "Intentions are cheap. A checklist is just a list of lies you tell yourself. We require physical, AI-verified proof that the work is done.",
            "viewfinder",
            MPColors.accent // Gold/Orange
        ),
        (
            "The Path of Resistance",
            "Forced Accountability",
            "Without a barrier, you'll always choose the path of least resistance. We create the friction you need to stay on track.",
            "figure.walk.motion",
            MPColors.primary // Teal
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: MPSpacing.xxl)

            // Headline Section
            VStack(spacing: MPSpacing.md) {
                Text("Willpower is a")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.textPrimary)
                +
                Text(" losing game.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(MPColors.error)

                Text("Your brain is wired to choose the screen over the routine.")
                    .font(.system(size: 15))
                    .foregroundColor(MPColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("We just change the rules.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(MPColors.textPrimary)
            }
            .padding(.horizontal, MPSpacing.xl)
            .opacity(showHeadline ? 1 : 0)
            .offset(y: showHeadline ? 0 : 10)

            Spacer()
                .frame(height: MPSpacing.xl)

            // Friction Cards
            VStack(spacing: MPSpacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    let card = frictionCards[index]
                    FrictionCard(
                        title: card.title,
                        tagline: card.tagline,
                        description: card.description,
                        icon: card.icon,
                        accentColor: card.color
                    )
                    .opacity(showCards[index] ? 1 : 0)
                    .offset(y: showCards[index] ? 0 : 20)
                }
            }
            .padding(.horizontal, MPSpacing.xl)

            Spacer()

            MPButton(title: "Set My Guardrails", style: .primary, icon: "shield.checkered") {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            // Animate headline first
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                showHeadline = true
            }
            // Stagger cards
            for i in 0..<3 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5 + Double(i) * 0.15)) {
                    showCards[i] = true
                }
            }
        }
    }
}

// MARK: - Friction Card Component

struct FrictionCard: View {
    let title: String
    let tagline: String
    let description: String
    let icon: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: MPSpacing.md) {
            // Icon with glow effect
            ZStack {
                // Outer glow
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .blur(radius: 6)

                // Icon container
                RoundedRectangle(cornerRadius: MPRadius.md)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(accentColor)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                // Title with tagline as subtitle
                HStack(alignment: .firstTextBaseline, spacing: MPSpacing.sm) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(MPColors.textPrimary)

                    Text(tagline)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(MPColors.textSecondary)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(MPSpacing.lg)
        .background(
            ZStack {
                MPColors.surface

                // Gradient glow from top-left
                LinearGradient(
                    colors: [accentColor.opacity(0.12), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
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
                .frame(height: 260)
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

            MPButton(title: "See the results", style: .primary) {
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

// MARK: - Step 7: Success Stories

struct SuccessStoriesStep: View {
    let onContinue: () -> Void
    @State private var showContent = false
    @State private var showStats = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.md) {
                    Text("Your first 10 days")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Based on tracked user data")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }
                .opacity(showContent ? 1 : 0)

                // Before/After comparison
                BeforeAfterCard(
                    beforeTitle: "Day 1",
                    beforeItems: ["Struggle to get out of bed", "Rush through morning", "Feel groggy until noon"],
                    afterTitle: "Day 10",
                    afterItems: ["Morning routine complete", "Calm, productive mornings", "Energized all afternoon"]
                )
                .padding(.horizontal, MPSpacing.xl)
                .opacity(showContent ? 1 : 0)

                // Success metrics
                HStack(spacing: MPSpacing.lg) {
                    TransformationStatCard(
                        value: "89%",
                        label: "snooze less by day 10",
                        icon: "alarm.fill",
                        color: MPColors.accent
                    )
                    TransformationStatCard(
                        value: "3.7x",
                        label: "more consistent than before",
                        icon: "flame.fill",
                        color: MPColors.primary
                    )
                    TransformationStatCard(
                        value: "80%",
                        label: "feel more productive",
                        icon: "bolt.fill",
                        color: MPColors.accentGold
                    )
                }
                .padding(.horizontal, MPSpacing.xl)
                .opacity(showStats ? 1 : 0)
                .offset(y: showStats ? 0 : 20)
            }

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                showStats = true
            }
        }
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
    @State private var showPills = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: MPSpacing.xxl) {
                VStack(spacing: MPSpacing.sm) {
                    Text("Tracking works")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(MPColors.textPrimary)

                    Text("Here's what the data shows")
                        .font(.system(size: 16))
                        .foregroundColor(MPColors.textSecondary)
                }

                StatisticRingCard(
                    percentage: 88,
                    label: "build lasting habits"
                )
                .padding(.horizontal, MPSpacing.xxl)

                // Research citation
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.primary)
                    Text("Journal of Behavioral Psychology, 2024")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MPColors.textTertiary)
                }

                // Supporting pills
                HStack(spacing: MPSpacing.sm) {
                    StatPillView(value: "10 days", label: "to transform", icon: "bolt.fill")
                    StatPillView(value: "35 days", label: "avg streak", icon: "flame.fill")
                    StatPillView(value: "96%", label: "recommend it", icon: "hand.thumbsup.fill")
                }
                .padding(.horizontal, MPSpacing.lg)
                .opacity(showPills ? 1 : 0)
                .offset(y: showPills ? 0 : 10)
            }

            Spacer()

            MPButton(title: "Continue", style: .primary) {
                onContinue()
            }
            .padding(.horizontal, MPSpacing.xxxl)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.5)) {
                showPills = true
            }
        }
    }
}

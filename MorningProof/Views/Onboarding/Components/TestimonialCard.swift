import SwiftUI

/// A testimonial card showing a user quote with avatar, location, and streak badge
struct TestimonialCard: View {
    let name: String
    let age: Int
    let location: String
    let quote: String
    let streakDays: Int
    let avatarIndex: Int

    // Avatar colors for variety
    private var avatarColors: [Color] {
        [MPColors.primary, MPColors.accent, MPColors.success, MPColors.accentGold, Color.purple, Color.pink]
    }

    private var avatarColor: Color {
        avatarColors[avatarIndex % avatarColors.count]
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.lg) {
            // Quote
            Text("\"\(quote)\"")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(MPColors.textPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            // User info row
            HStack(spacing: MPSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Text(initials)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(avatarColor)
                }

                // Name and location
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(MPColors.textPrimary)

                    Text("\(age), \(location)")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.textTertiary)
                }

                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 13))
                        .foregroundColor(MPColors.flameOrange)

                    Text("\(streakDays) days")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MPColors.flameOrange)
                }
                .padding(.horizontal, MPSpacing.md)
                .padding(.vertical, MPSpacing.sm)
                .background(MPColors.flameOrange.opacity(0.15))
                .cornerRadius(MPRadius.full)
            }
        }
        .padding(MPSpacing.xl)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
    }
}

/// Compact testimonial for horizontal scrolling
struct CompactTestimonialCard: View {
    let name: String
    let quote: String
    let streakDays: Int
    let avatarIndex: Int

    private var avatarColors: [Color] {
        [MPColors.primary, MPColors.accent, MPColors.success, MPColors.accentGold, Color.purple, Color.pink]
    }

    private var avatarColor: Color {
        avatarColors[avatarIndex % avatarColors.count]
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            // Quote (truncated)
            Text("\"\(quote)\"")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(MPColors.textPrimary)
                .lineLimit(3)
                .lineSpacing(2)

            Spacer()

            // User row
            HStack(spacing: MPSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 28, height: 28)

                    Text(initials)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(avatarColor)
                }

                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(MPColors.textSecondary)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(streakDays)")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(MPColors.flameOrange)
            }
        }
        .padding(MPSpacing.md)
        .frame(width: 220, height: 130)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.md)
        .mpShadow(.small)
    }
}

/// Testimonial data model
struct Testimonial: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let location: String
    let quote: String
    let streakDays: Int
}

/// Sample testimonials for onboarding
enum SampleTestimonials {
    static let all: [Testimonial] = [
        Testimonial(
            name: "Nick D.",
            age: 27,
            location: "Denver, CO",
            quote: "The app blocker is a game changer. I literally can't open Instagram until my bed is made. My mornings are mine again.",
            streakDays: 47
        ),
        Testimonial(
            name: "Cindy K.",
            age: 24,
            location: "Montreal, QC",
            quote: "The AI photo verification actually works. No more lying to myself about 'I'll do it later.'",
            streakDays: 83
        ),
        Testimonial(
            name: "Sharon S.",
            age: 31,
            location: "Miami, FL",
            quote: "Locking my apps until I complete my routine was the accountability I needed. 62 days and counting.",
            streakDays: 62
        ),
        Testimonial(
            name: "Jake G.",
            age: 22,
            location: "Parkland, FL",
            quote: "I used to doom scroll for an hour before getting up. Now I snap a photo of my made bed and I'm free to start my day.",
            streakDays: 156
        ),
        Testimonial(
            name: "Josh C.",
            age: 19,
            location: "Pittsburgh, PA",
            quote: "My phone used to control my mornings. Now Morning Proof keeps my distracting apps locked until I earn them back.",
            streakDays: 39
        )
    ]
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            TestimonialCard(
                name: "Nick D.",
                age: 27,
                location: "Denver, CO",
                quote: "The app blocker is a game changer. I literally can't open Instagram until my bed is made. My mornings are mine again.",
                streakDays: 47,
                avatarIndex: 0
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<3) { i in
                        CompactTestimonialCard(
                            name: SampleTestimonials.all[i].name,
                            quote: SampleTestimonials.all[i].quote,
                            streakDays: SampleTestimonials.all[i].streakDays,
                            avatarIndex: i
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

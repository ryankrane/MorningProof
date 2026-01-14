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
        VStack(alignment: .leading, spacing: MPSpacing.md) {
            // Quote
            Text("\"\(quote)\"")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(MPColors.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            // User info row
            HStack(spacing: MPSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(initials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(avatarColor)
                }

                // Name and location
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MPColors.textPrimary)

                    Text("\(age), \(location)")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.textTertiary)
                }

                Spacer()

                // Streak badge
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(MPColors.accent)

                    Text("\(streakDays) days")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(MPColors.accent)
                }
                .padding(.horizontal, MPSpacing.sm)
                .padding(.vertical, MPSpacing.xs)
                .background(MPColors.accentLight.opacity(0.3))
                .cornerRadius(MPRadius.full)
            }
        }
        .padding(MPSpacing.lg)
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
                .foregroundColor(MPColors.accent)
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
            name: "Sarah M.",
            age: 28,
            location: "Austin, TX",
            quote: "I used to scroll for an hour before getting up. Now I'm up and moving in 10 minutes.",
            streakDays: 47
        ),
        Testimonial(
            name: "Marcus J.",
            age: 34,
            location: "Brooklyn, NY",
            quote: "The AI verification actually works. Can't cheat myself anymore.",
            streakDays: 83
        ),
        Testimonial(
            name: "Rachel K.",
            age: 31,
            location: "Denver, CO",
            quote: "Finally found accountability that doesn't require a partner.",
            streakDays: 62
        ),
        Testimonial(
            name: "David L.",
            age: 42,
            location: "Portland, OR",
            quote: "My mornings used to be chaos. Now they're my favorite part of the day.",
            streakDays: 156
        ),
        Testimonial(
            name: "Michelle T.",
            age: 26,
            location: "Miami, FL",
            quote: "The photo verification seemed gimmicky at first. Now I actually look forward to making my bed.",
            streakDays: 39
        )
    ]
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            TestimonialCard(
                name: "Sarah M.",
                age: 28,
                location: "Austin, TX",
                quote: "I used to scroll for an hour before getting up. Now I'm up and moving in 10 minutes.",
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

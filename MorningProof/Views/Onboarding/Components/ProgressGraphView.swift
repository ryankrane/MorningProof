import SwiftUI

/// Animated line graph showing typical user improvement
struct ProgressGraphView: View {
    let dataPoints: [CGFloat]
    let labels: [String]
    let accentColor: Color

    @State private var animationProgress: CGFloat = 0
    @State private var showLabels = false

    init(
        dataPoints: [CGFloat] = [0.2, 0.35, 0.5, 0.65, 0.78, 0.85, 0.92],
        labels: [String] = ["Day 1", "Week 1", "Week 2", "Week 3", "Week 4", "Month 2", "Month 3"],
        accentColor: Color = MPColors.primary
    ) {
        self.dataPoints = dataPoints
        self.labels = labels
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(spacing: MPSpacing.md) {
            // Graph area
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let stepX = width / CGFloat(dataPoints.count - 1)

                ZStack {
                    // Grid lines
                    ForEach(0..<4) { i in
                        Path { path in
                            let y = height - (height * CGFloat(i + 1) / 4)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        .stroke(MPColors.border.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    }

                    // Area fill
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: height))

                        for (index, point) in dataPoints.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (point * height * animationProgress)
                            if index == 0 {
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }

                        path.addLine(to: CGPoint(x: width, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [accentColor.opacity(0.3), accentColor.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        for (index, point) in dataPoints.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (point * height * animationProgress)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                    // Data points
                    ForEach(0..<dataPoints.count, id: \.self) { index in
                        let x = CGFloat(index) * stepX
                        let y = height - (dataPoints[index] * height * animationProgress)

                        Circle()
                            .fill(accentColor)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                            .opacity(animationProgress)
                    }
                }
            }
            .frame(height: 150)

            // X-axis labels
            if showLabels && labels.count == dataPoints.count {
                HStack {
                    ForEach(0..<min(4, labels.count), id: \.self) { index in
                        let labelIndex = index == 0 ? 0 : (index == 3 ? labels.count - 1 : labels.count / 3 * index)
                        Text(labels[labelIndex])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(MPColors.textTertiary)
                        if index < 3 {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(MPSpacing.lg)
        .background(MPColors.surface)
        .cornerRadius(MPRadius.lg)
        .mpShadow(.small)
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                animationProgress = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
                showLabels = true
            }
        }
    }
}

/// Before/After comparison card with morphing X-to-checkmark animation
struct BeforeAfterCard: View {
    let beforeTitle: String
    let beforeItems: [String]
    let afterTitle: String
    let afterItems: [String]

    @State private var morphProgress: [CGFloat] = []
    @State private var showCard = false

    var body: some View {
        HStack(spacing: MPSpacing.md) {
            // Before side
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                // Header with morphing icon
                HStack(spacing: MPSpacing.xs) {
                    MorphingIcon(progress: morphProgress.isEmpty ? 0 : morphProgress[0])
                    Text(beforeTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MPColors.textPrimary)
                }

                ForEach(Array(beforeItems.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: MPSpacing.xs) {
                        MorphingBullet(progress: morphProgress.count > index + 1 ? morphProgress[index + 1] : 0)
                        Text(item)
                            .font(.system(size: 12))
                            .foregroundColor(MPColors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MPSpacing.md)
            .background(
                // Background morphs from red to green
                RoundedRectangle(cornerRadius: MPRadius.md)
                    .fill(morphingBackgroundColor)
            )

            // Arrow that pulses when morphing starts
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(morphProgress.first ?? 0 > 0.5 ? MPColors.success : MPColors.textTertiary)

            // After side
            VStack(alignment: .leading, spacing: MPSpacing.sm) {
                HStack(spacing: MPSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MPColors.success)
                    Text(afterTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MPColors.textPrimary)
                }

                ForEach(afterItems, id: \.self) { item in
                    HStack(spacing: MPSpacing.xs) {
                        Circle()
                            .fill(MPColors.success.opacity(0.5))
                            .frame(width: 6, height: 6)
                        Text(item)
                            .font(.system(size: 12))
                            .foregroundColor(MPColors.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(MPSpacing.md)
            .background(MPColors.successLight.opacity(0.3))
            .cornerRadius(MPRadius.md)
            .opacity(showCard ? 1 : 0)
            .offset(x: showCard ? 0 : 20)
        }
        .onAppear {
            // Initialize morph progress array (header + each item)
            morphProgress = Array(repeating: 0, count: beforeItems.count + 1)

            // Show the after card first
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showCard = true
            }

            // Then start the morphing animation with staggered delays
            let totalItems = beforeItems.count + 1
            for i in 0..<totalItems {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0 + Double(i) * 0.25)) {
                    morphProgress[i] = 1.0
                }
            }
        }
    }

    private var morphingBackgroundColor: Color {
        let avgProgress = morphProgress.isEmpty ? 0 : morphProgress.reduce(0, +) / CGFloat(morphProgress.count)
        return Color(
            red: 0.95 - avgProgress * 0.15,
            green: 0.85 + avgProgress * 0.1,
            blue: 0.85 + avgProgress * 0.05
        ).opacity(0.4)
    }
}

/// Icon that morphs from X to checkmark
private struct MorphingIcon: View {
    let progress: CGFloat

    var body: some View {
        ZStack {
            // X icon (fades out and shrinks)
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(MPColors.error)
                .opacity(1 - progress)
                .scaleEffect(1 - progress * 0.3)
                .rotationEffect(.degrees(Double(-progress) * 180.0))

            // Checkmark icon (fades in and grows)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(MPColors.success)
                .opacity(progress)
                .scaleEffect(0.7 + progress * 0.3)
                .rotationEffect(.degrees(Double(1 - progress) * 180.0))
        }
    }
}

/// Bullet that morphs from red to green
private struct MorphingBullet: View {
    let progress: CGFloat

    var body: some View {
        Circle()
            .fill(
                Color(
                    red: 0.9 - progress * 0.5,
                    green: 0.3 + progress * 0.5,
                    blue: 0.3
                ).opacity(0.3 + progress * 0.2)
            )
            .frame(width: 6, height: 6)
            .scaleEffect(1 + progress * 0.3)
    }
}

#Preview {
    VStack(spacing: 24) {
        ProgressGraphView()

        BeforeAfterCard(
            beforeTitle: "Before",
            beforeItems: ["Hit snooze 5 times", "Rush through morning", "Feel groggy until noon"],
            afterTitle: "After",
            afterItems: ["Wake up energized", "Calm, productive morning", "Focused all day"]
        )
    }
    .padding()
}

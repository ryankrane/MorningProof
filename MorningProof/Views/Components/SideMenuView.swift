import SwiftUI

enum SideMenuItem: String, CaseIterable, Identifiable {
    case today
    case history
    case calendar
    case achievements
    case statistics
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .history: return "History"
        case .calendar: return "Calendar"
        case .achievements: return "Achievements"
        case .statistics: return "Statistics"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .history: return "clock.arrow.circlepath"
        case .calendar: return "calendar"
        case .achievements: return "trophy.fill"
        case .statistics: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var isNavigationItem: Bool {
        switch self {
        case .today, .settings:
            return false
        default:
            return true
        }
    }
}

struct SideMenuView: View {
    @ObservedObject var manager: MorningProofManager
    @Binding var isShowing: Bool
    @Binding var selectedItem: SideMenuItem?

    let onDismiss: () -> Void
    let onSelectSettings: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Dimmed background
                if isShowing {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isShowing = false
                            }
                        }
                }

                // Menu content
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        menuHeader

                        // Menu items
                        VStack(spacing: MPSpacing.xs) {
                            ForEach(SideMenuItem.allCases.filter { $0 != .settings }) { item in
                                menuRow(item)
                            }
                        }
                        .padding(.horizontal, MPSpacing.lg)
                        .padding(.top, MPSpacing.lg)

                        Spacer()

                        // Settings at bottom
                        Divider()
                            .padding(.horizontal, MPSpacing.lg)
                            .padding(.vertical, MPSpacing.md)

                        menuRow(.settings)
                            .padding(.horizontal, MPSpacing.lg)
                            .padding(.bottom, MPSpacing.xxl)
                    }
                    .frame(width: min(280, geometry.size.width * 0.75))
                    .background(MPColors.surface)
                    .offset(x: isShowing ? 0 : -300)

                    Spacer()
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isShowing)
    }

    var menuHeader: some View {
        VStack(alignment: .leading, spacing: MPSpacing.sm) {
            HStack {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: MPIconSize.lg))
                    .foregroundColor(MPColors.accent)

                Text("Morning Proof")
                    .font(MPFont.headingSmall())
                    .foregroundColor(MPColors.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isShowing = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundColor(MPColors.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(MPColors.surfaceSecondary)
                        .cornerRadius(MPRadius.sm)
                }
            }

            // User greeting
            if !manager.settings.userName.isEmpty {
                Text("Hi, \(manager.settings.userName)")
                    .font(MPFont.bodyMedium())
                    .foregroundColor(MPColors.textSecondary)
            }

            // Streak badge
            HStack(spacing: MPSpacing.sm) {
                Image(systemName: "flame.fill")
                    .foregroundColor(MPColors.accent)
                Text("\(manager.currentStreak) day streak")
                    .font(MPFont.labelSmall())
                    .foregroundColor(MPColors.textSecondary)
            }
            .padding(.horizontal, MPSpacing.md)
            .padding(.vertical, MPSpacing.sm)
            .background(MPColors.accentLight)
            .cornerRadius(MPRadius.sm)
        }
        .padding(MPSpacing.xl)
        .background(MPColors.surfaceSecondary)
    }

    func menuRow(_ item: SideMenuItem) -> some View {
        let isSelected = selectedItem == item && item.isNavigationItem

        return Button {
            HapticManager.shared.lightTap()

            if item == .today {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isShowing = false
                }
            } else if item == .settings {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isShowing = false
                }
                onSelectSettings()
            } else {
                selectedItem = item
                withAnimation(.easeInOut(duration: 0.25)) {
                    isShowing = false
                }
            }
        } label: {
            HStack(spacing: MPSpacing.lg) {
                Image(systemName: item.icon)
                    .font(.system(size: MPIconSize.sm))
                    .foregroundColor(isSelected ? MPColors.primary : MPColors.textSecondary)
                    .frame(width: 24)

                Text(item.title)
                    .font(MPFont.labelMedium())
                    .foregroundColor(isSelected ? MPColors.primary : MPColors.textPrimary)

                Spacer()

                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(MPColors.primary)
                        .frame(width: 4, height: 20)
                }
            }
            .padding(.horizontal, MPSpacing.lg)
            .padding(.vertical, MPSpacing.md)
            .background(isSelected ? MPColors.primaryLight.opacity(0.3) : Color.clear)
            .cornerRadius(MPRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SideMenuView(
        manager: MorningProofManager.shared,
        isShowing: .constant(true),
        selectedItem: .constant(nil),
        onDismiss: {},
        onSelectSettings: {}
    )
}

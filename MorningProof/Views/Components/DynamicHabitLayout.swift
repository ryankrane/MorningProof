import SwiftUI

/// Calculates dynamic sizing for habit rows and lock button to fit everything on screen without scrolling
struct DynamicHabitLayout {
    let availableHeight: CGFloat
    let habitCount: Int

    // MARK: - Size Constraints

    /// Minimum habit height (still comfortably tappable per Apple HIG 44pt minimum)
    static let minHabitHeight: CGFloat = 48
    /// Maximum habit height (generous tappable area)
    static let maxHabitHeight: CGFloat = 90

    /// Lock button height range
    static let minLockButtonHeight: CGFloat = 44
    static let maxLockButtonHeight: CGFloat = 56

    /// Lock button width range (maintains aspect ratio)
    static let minLockButtonWidth: CGFloat = 180
    static let maxLockButtonWidth: CGFloat = 220

    // MARK: - Fixed Layout Elements

    /// Header section (greeting + date + menu button)
    static let headerHeight: CGFloat = 70
    /// Streak hero card (flame + stats)
    static let streakCardHeight: CGFloat = 180
    /// "Today's Habits" section header with edit button
    static let sectionHeaderHeight: CGFloat = 32
    /// Spacing between habits (MPSpacing.md = 12)
    static let habitSpacing: CGFloat = 12
    /// Padding around lock button (MPSpacing.lg = 16)
    static let lockButtonTopPadding: CGFloat = 16
    /// VStack spacing between major sections (MPSpacing.xl = 20)
    static let sectionSpacing: CGFloat = 20
    /// Bottom spacer (MPSpacing.xxxl = 32)
    static let bottomSpacer: CGFloat = 32
    /// Horizontal padding (MPSpacing.xl = 20)
    static let horizontalPadding: CGFloat = 20
    /// Top padding (MPSpacing.sm = 8)
    static let topPadding: CGFloat = 8

    // MARK: - Calculations

    /// Safety buffer for slight variations in actual heights vs calculated
    static let safetyBuffer: CGFloat = 8

    /// Calculates the height available for all habits combined
    private var heightForHabits: CGFloat {
        // Total fixed elements:
        // - Header + section spacing
        // - Streak card + section spacing
        // - Section header
        // - Lock button + top padding
        // - Bottom spacer
        // - Top padding
        // - Safety buffer

        let fixedHeight = Self.topPadding
            + Self.headerHeight
            + Self.sectionSpacing
            + Self.streakCardHeight
            + Self.sectionSpacing
            + Self.sectionHeaderHeight
            + Self.lockButtonTopPadding
            + Self.maxLockButtonHeight  // Use max to ensure it fits
            + Self.bottomSpacer
            + Self.safetyBuffer  // Account for slight variations

        // Subtract spacing between habits (includes one more gap for Lock In button row)
        let totalHabitSpacing = CGFloat(habitCount) * Self.habitSpacing

        return availableHeight - fixedHeight - totalHabitSpacing
    }

    /// The calculated height for each habit row
    var habitHeight: CGFloat {
        guard habitCount > 0 else { return Self.maxHabitHeight }

        let idealHeight = heightForHabits / CGFloat(habitCount)
        return min(Self.maxHabitHeight, max(Self.minHabitHeight, idealHeight))
    }

    /// Whether habits are at minimum size (compressed)
    var isCompressed: Bool {
        habitHeight <= Self.minHabitHeight + 4 // Small buffer
    }

    /// Compression ratio (0 = max size, 1 = min size)
    var compressionRatio: CGFloat {
        let range = Self.maxHabitHeight - Self.minHabitHeight
        let currentFromMax = Self.maxHabitHeight - habitHeight
        return min(1, max(0, currentFromMax / range))
    }

    /// Lock button height (scales with habit compression)
    var lockButtonHeight: CGFloat {
        let range = Self.maxLockButtonHeight - Self.minLockButtonHeight
        let reduction = range * compressionRatio * 0.5 // Only reduce by half as much
        return Self.maxLockButtonHeight - reduction
    }

    /// Lock button width (maintains proportion with height)
    var lockButtonWidth: CGFloat {
        let heightRatio = lockButtonHeight / Self.maxLockButtonHeight
        return Self.minLockButtonWidth + (Self.maxLockButtonWidth - Self.minLockButtonWidth) * heightRatio
    }

    /// Whether scrolling is needed (7+ habits can't fit)
    var needsScrolling: Bool {
        habitCount >= 7 && heightForHabits / CGFloat(habitCount) < Self.minHabitHeight
    }

    /// Internal padding for habit rows (adjusts based on compression)
    var habitInternalPadding: CGFloat {
        // Lerp between 16 (max) and 10 (min) based on compression
        let maxPadding: CGFloat = 16
        let minPadding: CGFloat = 10
        return maxPadding - (compressionRatio * (maxPadding - minPadding))
    }

    /// Icon size for habit rows (adjusts based on compression)
    var habitIconSize: CGFloat {
        // Lerp between 40 (max) and 32 (min) based on compression
        let maxSize: CGFloat = 40
        let minSize: CGFloat = 32
        return maxSize - (compressionRatio * (maxSize - minSize))
    }

    /// Spacing between habit rows (adjusts based on compression)
    var habitRowSpacing: CGFloat {
        // Lerp between 12 (max) and 8 (min) based on compression
        let maxSpacing: CGFloat = 12
        let minSpacing: CGFloat = 8
        return maxSpacing - (compressionRatio * (maxSpacing - minSpacing))
    }

    /// Lock button top padding (adjusts based on compression)
    var lockButtonPadding: CGFloat {
        // Lerp between 16 (max) and 8 (min) based on compression
        let maxPadding: CGFloat = 16
        let minPadding: CGFloat = 8
        return maxPadding - (compressionRatio * (maxPadding - minPadding))
    }
}

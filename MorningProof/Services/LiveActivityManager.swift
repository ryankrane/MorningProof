import Foundation
import ActivityKit
import SwiftUI

/// Manages Live Activities for the morning routine
@MainActor
class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()

    @Published private(set) var currentActivity: Activity<MorningRoutineAttributes>?
    @Published private(set) var isActivityActive: Bool = false

    private init() {
        // Check for any existing activities on launch
        checkExistingActivities()
    }

    // MARK: - Activity Lifecycle

    /// Starts a new Live Activity for the morning routine
    func startActivity(
        cutoffTime: Date,
        totalHabits: Int,
        currentStreak: Int
    ) {
        // Don't start if activities aren't supported
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            MPLogger.debug("Live Activities not enabled", category: MPLogger.liveActivity)
            return
        }

        // End any existing activity first
        if currentActivity != nil {
            Task {
                await endActivity(showCompletion: false)
            }
        }

        let attributes = MorningRoutineAttributes(
            cutoffTime: cutoffTime,
            startTime: Date()
        )

        let initialState = MorningRoutineAttributes.ContentState(
            completedHabits: 0,
            totalHabits: totalHabits,
            lastCompletedHabit: nil,
            currentStreakDays: currentStreak
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: cutoffTime),
                pushType: nil
            )

            currentActivity = activity
            isActivityActive = true
            MPLogger.debug("Started activity: \(activity.id)", category: MPLogger.liveActivity)

        } catch {
            MPLogger.error("Failed to start activity", error: error, category: MPLogger.liveActivity)
        }
    }

    /// Updates the Live Activity with new habit completion status
    func updateActivity(
        completedHabits: Int,
        totalHabits: Int,
        lastCompletedHabit: String?,
        currentStreak: Int
    ) async {
        guard let activity = currentActivity else {
            MPLogger.debug("No active activity to update", category: MPLogger.liveActivity)
            return
        }

        let updatedState = MorningRoutineAttributes.ContentState(
            completedHabits: completedHabits,
            totalHabits: totalHabits,
            lastCompletedHabit: lastCompletedHabit,
            currentStreakDays: currentStreak
        )

        await activity.update(
            ActivityContent(state: updatedState, staleDate: activity.attributes.cutoffTime)
        )

        MPLogger.debug("Updated: \(completedHabits)/\(totalHabits)", category: MPLogger.liveActivity)

        // Auto-end if all habits completed
        if completedHabits >= totalHabits {
            await endActivity(showCompletion: true)
        }
    }

    /// Ends the Live Activity
    func endActivity(showCompletion: Bool = false) async {
        guard let activity = currentActivity else { return }

        let finalState = MorningRoutineAttributes.ContentState(
            completedHabits: activity.content.state.completedHabits,
            totalHabits: activity.content.state.totalHabits,
            lastCompletedHabit: showCompletion ? "All complete!" : nil,
            currentStreakDays: activity.content.state.currentStreakDays
        )

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: showCompletion ? .after(.now + 30) : .immediate
        )

        currentActivity = nil
        isActivityActive = false
        MPLogger.debug("Ended activity", category: MPLogger.liveActivity)
    }

    /// Ends activity when cutoff time is reached
    func endActivityAtCutoff() async {
        guard let activity = currentActivity else { return }

        let wasComplete = activity.content.state.completedHabits >= activity.content.state.totalHabits

        let finalState = MorningRoutineAttributes.ContentState(
            completedHabits: activity.content.state.completedHabits,
            totalHabits: activity.content.state.totalHabits,
            lastCompletedHabit: wasComplete ? "Perfect morning!" : "Time's up",
            currentStreakDays: activity.content.state.currentStreakDays
        )

        await activity.end(
            ActivityContent(state: finalState, staleDate: nil),
            dismissalPolicy: .after(.now + 60)
        )

        currentActivity = nil
        isActivityActive = false
    }

    // MARK: - Helpers

    private func checkExistingActivities() {
        // Find any running activities from a previous session
        for activity in Activity<MorningRoutineAttributes>.activities {
            if activity.activityState == .active {
                currentActivity = activity
                isActivityActive = true
                MPLogger.debug("Found existing activity: \(activity.id)", category: MPLogger.liveActivity)
                break
            }
        }
    }

    /// Check if Live Activities are available on this device
    var areActivitiesAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
}

// MARK: - MorningRoutineAttributes (Shared with Widget)
// IMPORTANT: This definition MUST remain identical to MorningProofWidget/MorningRoutineLiveActivity.swift
// Both the main app and widget extension need this type for Live Activities to work.
// If you modify this, you MUST update the widget version as well.
struct MorningRoutineAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var completedHabits: Int
        var totalHabits: Int
        var lastCompletedHabit: String?
        var currentStreakDays: Int
    }

    var cutoffTime: Date
    var startTime: Date
}

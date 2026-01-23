import SwiftUI
import StoreKit
import AuthenticationServices
import FamilyControls
import SuperwallKit

// MARK: - Onboarding Data Model

class OnboardingData: ObservableObject {
    @Published var userName: String = ""
    @Published var gender: Gender? = nil
    @Published var morningStruggles: Set<MorningStruggle> = []
    @Published var trackingStatus: TrackingStatus? = nil
    @Published var primaryGoal: PrimaryGoal? = nil
    @Published var obstacles: Set<Obstacle> = []
    @Published var desiredOutcomes: Set<DesiredOutcome> = []
    @Published var healthConnected: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var selectedHabits: Set<HabitType> = []
    // Note: With Family Controls enabled, app selection is stored via ScreenTimeManager
    // This property is only used as a fallback when Family Controls is disabled
    @Published var selectedDistractionNames: Set<String> = []

    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case preferNotToSay = "Prefer not to say"

        var icon: String {
            switch self {
            case .male: return "figure.stand"
            case .female: return "figure.stand.dress"
            case .preferNotToSay: return "person.fill.questionmark"
            }
        }
    }

    enum MorningStruggle: String, CaseIterable {
        case noRoutine = "I don't have a routine"
        case scrollInBed = "I scroll in bed for way too long"
        case feelBehind = "I feel behind before the day even starts"
        case knowButDont = "I know what to do but don't do it"
        case lackConsistency = "I lack consistency"
        case morningsBattle = "Mornings feel like a battle"

        var icon: String {
            switch self {
            case .noRoutine: return "list.bullet.clipboard"
            case .scrollInBed: return "iphone"
            case .feelBehind: return "clock.badge.exclamationmark"
            case .knowButDont: return "brain.head.profile"
            case .lackConsistency: return "arrow.triangle.2.circlepath"
            case .morningsBattle: return "figure.boxing"
            }
        }
    }

    enum PrimaryGoal: String, CaseIterable {
        case setHabits = "Set new habits"
        case maintainHabits = "Maintain existing habits"

        var icon: String {
            switch self {
            case .setHabits: return "plus.circle.fill"
            case .maintainHabits: return "checkmark.circle.fill"
            }
        }

        var description: String {
            switch self {
            case .setHabits: return "Build a consistent morning routine from scratch"
            case .maintainHabits: return "Stay accountable to habits you've already started"
            }
        }
    }

    enum Obstacle: String, CaseIterable {
        case lackMotivation = "Lack of motivation"
        case forgetful = "I forget to do them"
        case noTime = "Not enough time"
        case noAccountability = "No accountability"
        case overwhelmed = "Feel overwhelmed"
        case inconsistent = "Inconsistent schedule"

        var icon: String {
            switch self {
            case .lackMotivation: return "battery.25"
            case .forgetful: return "brain"
            case .noTime: return "clock.fill"
            case .noAccountability: return "person.slash.fill"
            case .overwhelmed: return "tornado"
            case .inconsistent: return "calendar.badge.exclamationmark"
            }
        }
    }

    enum DesiredOutcome: String, CaseIterable {
        case feelInControl = "Feel in control"
        case increaseProductivity = "Increase productivity"
        case buildSelfDiscipline = "Build self-discipline"
        case buildLastingHabits = "Build lasting habits"
        case improveMood = "Improve mood"
        case improveFocus = "Improve focus"

        var icon: String {
            switch self {
            case .feelInControl: return "hand.raised.fill"
            case .increaseProductivity: return "chart.line.uptrend.xyaxis"
            case .buildSelfDiscipline: return "flame.fill"
            case .buildLastingHabits: return "hammer.fill"
            case .improveMood: return "face.smiling.fill"
            case .improveFocus: return "target"
            }
        }
    }

    enum TrackingStatus: String, CaseIterable {
        case yesConsistently = "Yes, I track consistently"
        case yesNotEnough = "Yes, but not as much as I'd like"
        case no = "No, I don't track yet"

        var icon: String {
            switch self {
            case .yesConsistently: return "checkmark.circle.fill"
            case .yesNotEnough: return "circle.dotted"
            case .no: return "xmark.circle.fill"
            }
        }
    }
}

// MARK: - Onboarding Flow View (17 Steps - Obstacles removed)

struct OnboardingFlowView: View {
    @ObservedObject var manager: MorningProofManager
    @StateObject private var onboardingData = OnboardingData()
    private var authManager: AuthenticationManager { AuthenticationManager.shared }
    private var subscriptionManager: SubscriptionManager { SubscriptionManager.shared }
    @State private var currentStep = 0

    private let totalSteps = 18
    private let paywallStep = 17

    var body: some View {
        ZStack {
            MPColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar (show for steps 2-17, not welcome or paywall)
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps - 2)
                        .padding(.horizontal, MPSpacing.xl)
                        .padding(.top, MPSpacing.md)
                }

                // Content
                Group {
                    switch currentStep {
                    // Phase 1: Hook & Identity (Steps 0-3) — Phase1Steps.swift
                    case 0: WelcomeHeroStep(onContinue: nextStep)
                    case 1: NameStep(data: onboardingData, onContinue: nextStep)
                    case 2: MorningStruggleStep(data: onboardingData, onContinue: nextStep)
                    case 3: DesiredOutcomeStep(data: onboardingData, onContinue: nextStep)

                    // Phase 2: Problem Agitation (Steps 4-5) — Phase2Steps.swift
                    case 4: GuardrailStep(onContinue: nextStep)
                    case 5: DoomScrollingSimulatorStep(onContinue: nextStep)

                    // Phase 3: Solution Setup (Steps 6-9) — Phase3Steps.swift
                    case 6: DistractionSelectionStep(data: onboardingData, onContinue: nextStep)
                    case 7: AppLockingOnboardingStep(onContinue: nextStep)
                    case 8: HowItWorksStep(onContinue: nextStep)
                    case 9: AIVerificationShowcaseStep(onContinue: nextStep)

                    // Phase 4: Social Proof (Steps 10-12) — Phase4Steps.swift
                    case 10: YouAreNotAloneStep(onContinue: nextStep)
                    case 11: SuccessStoriesStep(onContinue: nextStep)
                    case 12: TrackingComparisonStep(onContinue: nextStep)

                    // Phase 5: Personalization (Step 13) — Phase5Steps.swift
                    case 13: PermissionsStep(data: onboardingData, onContinue: nextStep)

                    // Phase 6: Conversion (Steps 14-17) — Phase6Steps.swift
                    case 14: OptionalRatingStep(onContinue: nextStep)
                    case 15: AnalyzingStep(data: onboardingData, onComplete: nextStep)
                    case 16: YourHabitsStep(data: onboardingData, onContinue: nextStep)
                    case 17: HardPaywallStep(
                        subscriptionManager: subscriptionManager,
                        onSubscribe: completeOnboarding,
                        onBack: previousStep
                    )

                    default: EmptyView()
                    }
                }
                .id(currentStep)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func nextStep() {
        // If user just signed in, prefill their name
        if currentStep == 0, let user = authManager.currentUser {
            if let fullName = user.fullName, !fullName.isEmpty {
                let firstName = fullName.components(separatedBy: " ").first ?? fullName
                onboardingData.userName = firstName
            }
        }

        currentStep += 1
    }

    private func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    private func completeOnboarding() {
        manager.settings.userName = onboardingData.userName

        for habitType in HabitType.allCases {
            let isEnabled = onboardingData.selectedHabits.contains(habitType)
            manager.updateHabitConfig(habitType, isEnabled: isEnabled)
        }

        manager.completeOnboarding()
    }
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(MPColors.progressBg)
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 3)
                    .fill(MPColors.primary)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Distraction Selection Step Wrapper

private struct DistractionSelectionStep: View {
    @ObservedObject var data: OnboardingData
    let onContinue: () -> Void

    var body: some View {
        // Family Controls version stores selection via ScreenTimeManager directly
        DistractionSelectionView { _ in
            onContinue()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingFlowView(manager: MorningProofManager.shared)
}

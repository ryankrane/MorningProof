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
    @Published var attributionSource: AttributionSource? = nil

    enum AttributionSource: String, CaseIterable {
        case appStore = "App Store"
        case instagram = "Instagram"
        case reddit = "Reddit"
        case tiktok = "TikTok"
        case friend = "Friend"
        case other = "Other"

        var icon: String {
            switch self {
            case .tiktok: return "music.note"
            case .instagram: return "camera.fill"
            case .friend: return "person.2.fill"
            case .appStore: return "square.stack.3d.up.fill"
            case .reddit: return "bubble.left.and.bubble.right.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var iconColor: Color {
            switch self {
            case .tiktok: return Color(red: 0.0, green: 0.9, blue: 0.9)
            case .instagram: return Color(red: 0.91, green: 0.27, blue: 0.53)
            case .friend: return Color(red: 0.4, green: 0.6, blue: 1.0)
            case .appStore: return Color(red: 0.0, green: 0.48, blue: 1.0)
            case .reddit: return Color(red: 1.0, green: 0.35, blue: 0.14)
            case .other: return MPColors.textSecondary
            }
        }
    }

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

// MARK: - Onboarding Flow View (18 Steps - App blocking consolidated)

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
                // Header with progress bar (centered) and back button (overlaid)
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    HStack(spacing: 0) {
                        // Leading spacer/button area - fixed width for balance
                        Button(action: previousStep) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(MPColors.textSecondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .opacity(currentStep > 1 && currentStep < 15 ? 1 : 0)
                        .disabled(currentStep <= 1 || currentStep >= 15)

                        // Progress bar - centered, takes remaining space
                        OnboardingProgressBar(currentStep: currentStep, totalSteps: totalSteps - 2)

                        // Trailing spacer - same width as leading for balance
                        Spacer()
                            .frame(width: 44)
                    }
                    .padding(.horizontal, MPSpacing.md)
                    .padding(.top, MPSpacing.md)
                    .animation(.easeInOut(duration: 0.25), value: currentStep)
                }

                // Content
                Group {
                    switch currentStep {
                    // Phase 1: Hook & Identity (Steps 0-4) — Phase1Steps.swift + AttributionStep.swift
                    case 0: WelcomeHeroStep(onContinue: nextStep)
                    case 1: NameStep(data: onboardingData, onContinue: nextStep)
                    case 2: MorningStruggleStep(data: onboardingData, onContinue: nextStep)
                    case 3: DesiredOutcomeStep(data: onboardingData, onContinue: nextStep)
                    case 4: AttributionStep(data: onboardingData, onContinue: nextStep)

                    // Phase 2: Problem Agitation (Steps 5-6) — Phase2Steps.swift
                    case 5: GuardrailStep(onContinue: nextStep)
                    case 6: DoomScrollingSimulatorStep(onContinue: nextStep)

                    // Phase 3: Solution Setup (Steps 7-9) — Phase3Steps.swift + DistractionSelectionView.swift
                    case 7: AppBlockingExplainerStep(onContinue: nextStep)
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

// MARK: - Preview

#Preview {
    OnboardingFlowView(manager: MorningProofManager.shared)
}

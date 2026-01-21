# MorningProof

## Developer Context
First-time app developer, but fast learner. When explaining things, include big-picture context about why something works the way it does - not just how to fix it. Explain iOS/Swift concepts along the way when relevant.

## Claude Instructions
When you learn something important about this project (gotchas, patterns, decisions, or context that would help future sessions), add it to this file. Keep it concise.

## Design Quality Principle
Every feature and UI element must feel well thought out. The app should feel polished and premium, not cheaply made. This doesn't mean overcomplicating things - it means taking an extra moment to consider the best approach and cool ideas before implementing. Go above and beyond, but keep solutions simple and elegant.

## What This App Does
Morning habit tracking app that uses photo verification (AI checks if you made your bed) to build streaks and accountability.

## Git Workflow
- **main branch**: Default branch for all work. Pushing to main triggers Xcode Cloud → TestFlight build.
- **dev branch**: Use only when explicitly requested for experimental work.

## Tech Stack
- SwiftUI + SwiftData
- Firebase (Functions, Crashlytics, Analytics)
- Sign in with Apple
- Widget extension (MorningProofWidget)
- Claude API (via Firebase Functions for secure API key handling)

## Firebase & Claude API Setup

The app uses Firebase Cloud Functions to securely call the Claude API. This keeps the API key on the server (not in the app binary).

### How It Works
1. iOS app calls Firebase Callable Functions (via FirebaseFunctions SDK)
2. Firebase Function reads `CLAUDE_API_KEY` from Google Cloud Secret Manager
3. Function calls Claude API and returns result to app

### Key Files
- `functions/index.js` - Firebase Functions that call Claude API
- `MorningProof/Services/ClaudeAPIService.swift` - iOS service that calls Firebase
- `MorningProof/Resources/GoogleService-Info.plist` - Firebase config
- `MorningProof/Services/Secrets.swift` - Contains Firebase Functions URL (not in git, created by ci_post_clone.sh for Xcode Cloud)

### Xcode Cloud Setup
The `ci_scripts/ci_post_clone.sh` script creates `Secrets.swift` from environment variables. Only `FIREBASE_FUNCTIONS_URL` is needed since the Claude API key lives in Google Cloud Secret Manager (not in the app).

### Deploying Functions
```bash
firebase deploy --only functions
```

### Model Name
Uses `claude-haiku-4-5` for fast, cheap image verification. Update in `functions/index.js` (CLAUDE_MODEL constant). The legacy direct API fallback in ClaudeAPIService.swift is not used.

## Project Structure
- `/MorningProof/Views/` - UI screens
- `/MorningProof/ViewModels/` - Business logic
- `/MorningProof/Models/` - Data models (SwiftData in `/Models/SwiftData/`)
- `/MorningProof/Theme/` - ThemeManager for appearance
- `/MorningProof/Resources/` - Info.plist, assets

## Key Managers
- `MorningProofManager` - Main app state
- `NotificationManager` - Push notifications
- `AuthenticationManager` - Sign in with Apple
- `ThemeManager` - Light/dark mode
- `ScreenTimeManager` - App blocking via Family Controls API
- `HealthKitBackgroundDeliveryService` - Background health goal notifications

## HealthKit Background Delivery

The app uses `HKObserverQuery` + `enableBackgroundDelivery()` to receive HealthKit updates even when the app is not running. This enables immediate notifications when users complete health goals.

### How It Works
1. `HealthKitBackgroundDeliveryService` registers observers for steps, sleep, and workouts
2. When HealthKit has new data, it wakes the app and calls the observer's handler
3. The handler fetches current data, checks against goals, sends notification if met
4. "Already notified today" state tracked in UserDefaults to prevent duplicate notifications

### Key Gotchas
- **Observer completion handler MUST be called** - or HealthKit throttles future deliveries
- **Cannot access @MainActor managers in background** - service reads settings from UserDefaults directly
- **Background delivery doesn't work in simulator** - must test on device
- **Timing not guaranteed** - `.immediate` is a request, actual delivery can be delayed by minutes

### Adding New Health Goal Notifications
To add background notifications for a new health metric:
1. Add observer in `registerObservers()`
2. Enable background delivery for the type
3. Add handler method (e.g., `handleNewDataChange()`)
4. Add notification tracking key to prevent duplicates
5. Add goal getter that reads from stored habit configs

## Screen Time Extensions (App Blocking Feature)
Three extensions are required for app blocking functionality:
- `MorningProofActivityMonitor` - Monitors schedule, applies/removes shields at midnight/cutoff
- `MorningProofShieldConfig` - Customizes the blocking overlay appearance
- `MorningProofShieldAction` - Handles "Open Morning Proof" button tap on shield

Shared data between app and extensions uses App Group: `group.com.rk.morningproof`

## App Identifiers
- Bundle ID: `com.rk.morningproof`
- App Store ID: `6757691737`
- Team ID: `P9ZXADV42A`
- Google OAuth Client: `591131827329-487r1epolmgvbq8vdf3cje54qlpmi0a3.apps.googleusercontent.com`
- Support Email: `support@morningproofapp.com`

## Build Commands
When building for simulator, use `iPhone 17 Pro`:
```bash
xcodebuild -project MorningProof.xcodeproj -scheme MorningProof -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Gotchas & Learnings
- Don't add `UIBackgroundModes: processing` to Info.plist unless you also add `BGTaskSchedulerPermittedIdentifiers` with task IDs - Apple will reject the build (ITMS-90771)
- Version numbers need to be updated in both `project.yml` AND `project.pbxproj` (MARKETING_VERSION)
- `project.yml` also defines Info.plist properties - changes there can override the actual Info.plist file
- Google Sign-In requires `GIDClientID` and `CFBundleURLTypes` in Info.plist - project.yml may not merge these correctly, so add them directly to Info.plist
- Screen Time extensions can't access SwiftData/CoreData - must use App Group UserDefaults for shared data
- Each Screen Time extension needs its own entitlements file with `com.apple.developer.family-controls` and App Group
- xcodegen may clear entitlements files - add `properties:` section in project.yml to preserve them
- When defining local model types in Views (like `Achievement`), watch for naming conflicts with types in Models folder
- **Onboarding animations**: Don't use `.animation()` on a ZStack/Group containing a switch statement for step transitions - it causes views to overlap. Use `.id(currentStep)` instead to force SwiftUI to replace the view entirely
- **StoreKit async sequences**: Calling `Transaction.currentEntitlements` immediately at app launch can cause freezing in simulator. Added a 2-second delay before Superwall sync in `MorningProofApp.swift` to avoid startup issues
- **Hold-to-complete gestures in ScrollView**: SwiftUI gestures (`LongPressGesture`, `DragGesture`) block ScrollView scrolling because they don't have access to UIKit's gesture recognizer properties. The fix is to use a UIKit-based `UILongPressGestureRecognizer` via `UIViewRepresentable` with: (1) `cancelsTouchesInView = false` to allow touches to pass to ScrollView, (2) `allowableMovement = 10` to fail when scrolling, (3) `shouldRequireFailureOf` returning true for `UIPanGestureRecognizer` to give scrolling priority. See `HoldGestureView.swift`
- **New Swift files require xcodegen**: After creating new `.swift` files, run `xcodegen generate` to add them to the Xcode project. The project uses xcodegen to manage the xcodeproj - files won't compile until added to the project.

## TEMPORARILY DISABLED: Screen Time / App Blocking Feature
The Screen Time (Family Controls) feature is temporarily disabled while waiting for Apple to approve all bundle IDs. To re-enable once approved:

### Files with `#if false` guards (change to `#if true`):
1. **ScreenTimeManager.swift** - top of file
2. **AppLockingSettingsView.swift** - top of file
3. **DistractionSelectionView.swift** - top of file (enables real app picker)
4. **Phase3Steps.swift** - `AppLockingOnboardingStep` near bottom of file

### Other code changes (search for "TODO: FAMILY CONTROLS" comments):

5. **Phase3Steps.swift (HowItWorksStep)** - Revert these text changes:
   - Row 2: "Set your deadline" → "Lock distractions"
   - Row 2 description: "Pick a time to finish by each day" → "Apps blocked until you're done"
   - Row 2 icon: "clock.fill" → "lock.shield.fill"
   - Row 3: "Prove it with AI" → "Prove it & unlock"
   - Row 3 description: "Snap a photo, AI verifies you did it" → "AI verifies, then apps unlock"
   - Row 3 icon: "camera.viewfinder" → "lock.open.fill"

6. **Phase3Steps.swift (AIVerificationShowcaseStep)** - Uncomment the "unlock message" section that says "Once verified, your apps unlock instantly"

7. **Phase5Steps.swift (PermissionsStep)** - Uncomment the App Locking PermissionCard

8. **OnboardingFlowView.swift**:
   - Uncomment `import FamilyControls`
   - Uncomment `DistractionSelectionStep` (case 6) and `AppLockingOnboardingStep` (case 7)
   - Increment all case numbers below them by 2
   - Update `totalSteps` from 16 to 18
   - Update `paywallStep` from 15 to 17

9. **project.yml**: Uncomment the extension targets and `family-controls` entitlement (search for "TEMPORARILY DISABLED")

10. **MorningProofSettingsView.swift**: Uncomment `appLockingSection` in the body

11. **MorningProofManager.swift**: Uncomment `checkForEmergencyUnlock()` and `ensureShieldsAppliedIfNeeded()` calls

12. Run `xcodegen generate` to regenerate the project

## Paywall
The app uses Superwall for the paywall. The paywall shows for all users (TestFlight and App Store). TestFlight testers can use sandbox accounts to test purchases without real charges.

## TODO: Pre-Release Checklist
When ready for App Store release (after Family Controls approval):

### Re-enable Screen Time Feature
- [ ] Re-enable Screen Time feature once all bundle IDs are approved for Family Controls (see section above)

### HealthKit (once approved)
- [ ] Review if Apple requires additional HealthKit privacy disclosures in Info.plist (NSHealthShareUsageDescription, NSHealthUpdateUsageDescription)
- [ ] Verify App Store Connect Privacy Nutrition Labels include HealthKit data types (sleep, steps, workouts)
- [ ] Confirm privacy policy on GitHub Pages covers all HealthKit usage (already updated but double-check after approval)

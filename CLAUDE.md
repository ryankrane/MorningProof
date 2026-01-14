# MorningProof

## Developer Context
First-time app developer, but fast learner. When explaining things, include big-picture context about why something works the way it does - not just how to fix it. Explain iOS/Swift concepts along the way when relevant.

## Claude Instructions
When you learn something important about this project (gotchas, patterns, decisions, or context that would help future sessions), add it to this file. Keep it concise.

## What This App Does
Morning habit tracking app that uses photo verification (AI checks if you made your bed) to build streaks and accountability.

## Git Workflow
- **main branch**: Default branch for all work. Pushing to main triggers Xcode Cloud → TestFlight build.
- **dev branch**: Use only when explicitly requested for experimental work.

## Tech Stack
- SwiftUI + SwiftData
- Firebase (configured but not active yet)
- Sign in with Apple
- Widget extension (MorningProofWidget)

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

## App Identifiers
- Bundle ID: `com.rk.morningproof`
- App Store ID: `6757691737`
- Team ID: `P9ZXADV42A`
- Google OAuth Client: `591131827329-487r1epolmgvbq8vdf3cje54qlpmi0a3.apps.googleusercontent.com`

## Gotchas & Learnings
- Don't add `UIBackgroundModes: processing` to Info.plist unless you also add `BGTaskSchedulerPermittedIdentifiers` with task IDs - Apple will reject the build (ITMS-90771)
- Version numbers need to be updated in both `project.yml` AND `project.pbxproj` (MARKETING_VERSION)
- `project.yml` also defines Info.plist properties - changes there can override the actual Info.plist file
- Google Sign-In requires `GIDClientID` and `CFBundleURLTypes` in Info.plist - project.yml may not merge these correctly, so add them directly to Info.plist
- Don't access `@MainActor` singletons as stored properties in the App struct - causes deadlock. Move them to a nested View struct instead

## TODO: Pre-Release Checklist
- [ ] **REMOVE SKIP BUTTON** in `HardPaywallStep.swift` before App Store release - it's for testing only!

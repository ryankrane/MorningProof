# MorningProof

## Developer Context
First-time app developer, but fast learner. When explaining things, include big-picture context about why something works the way it does - not just how to fix it. Explain iOS/Swift concepts along the way when relevant.

## Claude Instructions
When you learn something important about this project (gotchas, patterns, decisions, or context that would help future sessions), add it to this file. Keep it concise.

## What This App Does
Morning habit tracking app that uses photo verification (AI checks if you made your bed) to build streaks and accountability.

## Git Workflow
- **dev branch**: All development work happens here. Push freely.
- **main branch**: Merging to main triggers Xcode Cloud → TestFlight build.

To deploy: `git checkout main && git merge dev && git push && git checkout dev`

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

## Gotchas & Learnings
- Don't add `UIBackgroundModes: processing` to Info.plist unless you also add `BGTaskSchedulerPermittedIdentifiers` with task IDs - Apple will reject the build (ITMS-90771)

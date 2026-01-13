# MorningProof

## Developer Context
First-time app builder - be extra careful with implementations. Before making changes, think through what else might be affected and whether other files need to be updated as a result. Explain iOS/Swift concepts along the way when relevant, including the big-picture context of why something works the way it does.

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
- Sign in with Apple + Google Sign-In
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
- `AuthenticationManager` - Sign in with Apple & Google
- `ThemeManager` - Light/dark mode

## App IDs
- **Bundle ID:** `com.rk.morningproof`
- **App Store ID:** `6757691737`
- **Team ID:** `P9ZXADV42A`
- **Google Client ID:** `591131827329-487r1epolmgvbq8vdf3cje54qlpmi0a3.apps.googleusercontent.com`

## Gotchas & Learnings
- Don't add `UIBackgroundModes: processing` to Info.plist unless you also add `BGTaskSchedulerPermittedIdentifiers` with task IDs - Apple will reject the build (ITMS-90771)
- Version numbers need to be updated in both `project.yml` AND `project.pbxproj` (MARKETING_VERSION)
- `project.yml` also defines Info.plist properties - changes there can override the actual Info.plist file
- **Yellow build warnings**: Swift complains about unused variables. Use `_` instead of a named variable in loops/closures when you don't need the value (e.g., `ForEach(0..<5) { _ in }` instead of `{ index in }`)

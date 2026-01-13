# MorningProof

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

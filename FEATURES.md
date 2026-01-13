# Morning Proof - Feature Roadmap

## Currently Implementing
- [ ] Home Screen Widget
- [ ] Dark Mode Support
- [ ] Crash Reporting (Firebase Crashlytics)
- [ ] Live Activities (deadline countdown)
- [ ] iCloud Sync
- [ ] Local-First Architecture
- [ ] SwiftData Migration

---

## Future Features

### Authentication & Account
- [ ] **Google Sign-In** - Alternative login option alongside Apple
- [ ] **Improved Apple Authentication** - Better error handling, re-authentication flows
- [ ] **Account linking** - Connect multiple auth providers to one account
- [ ] **Account deletion flow** - App Store requirement compliance

### Monetization
- [ ] **Rethink pricing strategy** - Research optimal price points
- [ ] **Streak recovery pricing** - Currently $0.99, evaluate if this is optimal
- [ ] **Family sharing** - Allow family members to share subscription
- [ ] **Lifetime purchase option** - One-time payment tier
- [ ] **Free trial optimization** - A/B test trial lengths
- [ ] **Promotional offers** - Seasonal discounts, referral codes

### Onboarding & Psychology
- [ ] **Psychology-driven onboarding** - Deep dive into why habits work
- [ ] **Made bed psychology** - Research on how making bed affects mindset
- [ ] **Identity-based framing** - "I am someone who..." approach (like Atoms app)
- [ ] **Habit stacking education** - Teach users to chain habits
- [ ] **Progressive habit unlocking** - Start with 1-2 habits, earn more
- [ ] **Personalized journey** - Guided multi-day onboarding (like Fabulous)

### Platform Features
- [ ] **Apple Watch App** - Quick habit logging from wrist
- [ ] **Siri Shortcuts / App Intents** - Voice-activated habit logging
- [ ] **Spotlight Search** - Search habits and stats
- [ ] **Control Center Widget** (iOS 18)
- [ ] **iPad Support** - Optimized layout for larger screens

### Social & Accountability
- [ ] **Morning buddy** - Pair with a friend for accountability
- [ ] **Share streaks** - Social sharing of achievements
- [ ] **Leaderboards** - Compete with friends
- [ ] **Community challenges** - Group goals

### Analytics & Insights
- [ ] **Detailed statistics** - Trends, patterns, correlations
- [ ] **Weekly/monthly reports** - Summary emails or in-app
- [ ] **Mood correlation** - Track mood vs habit completion
- [ ] **Best performing days** - Identify what makes successful mornings

### Data & Privacy
- [ ] **Data export** - Download all user data (GDPR)
- [ ] **Privacy dashboard** - See what data is collected
- [ ] **Offline mode indicators** - Show sync status

### Accessibility
- [ ] **Dynamic Type support** - Adjustable font sizes
- [ ] **VoiceOver optimization** - Full screen reader support
- [ ] **Reduce Motion** - Respect system animation preferences
- [ ] **High contrast mode** - For visibility

### Advanced Habit Features
- [ ] **Flexible scheduling** - X times per week instead of daily
- [ ] **Streak grace days** - Don't break streak for planned rest
- [ ] **Habit notes** - Add notes to any completion
- [ ] **Custom habits** - User-defined habits beyond the 9 presets
- [ ] **Habit reminders per-habit** - Individual notification times

### AI Features
- [ ] **AI coaching** - Personalized tips based on performance
- [ ] **Smart recommendations** - Suggest which habit to focus on
- [ ] **Pattern detection** - "You tend to miss habits on Mondays"

---

## Completed Features
- [x] Core habit tracking (9 habits)
- [x] AI bed verification (Claude Vision)
- [x] HealthKit integration (steps, sleep)
- [x] Streak system with achievements
- [x] Sign in with Apple
- [x] Local notifications
- [x] Premium subscriptions (StoreKit 2)
- [x] Streak recovery purchase
- [x] Celebration animations
- [x] Haptic feedback

---

## Notes
- Prioritize features that increase retention (widgets, notifications, streaks)
- Always test on real devices before release
- Keep bundle size reasonable
- Consider App Store guidelines for each feature

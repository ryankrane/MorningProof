import SwiftUI

struct ResultView: View {
    @EnvironmentObject var viewModel: BedVerificationViewModel

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                if let result = viewModel.lastResult {
                    if result.isMade {
                        SuccessContent(result: result, streakData: viewModel.streakData)
                    } else {
                        FailureContent(result: result)
                    }
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if let result = viewModel.lastResult, !result.isMade {
                        Button {
                            viewModel.openCamera()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill")
                                Text("Try Again")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .cornerRadius(16)
                        }
                    }

                    Button {
                        viewModel.goHome()
                    } label: {
                        Text(viewModel.lastResult?.isMade == true ? "Done" : "Cancel")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.55, green: 0.45, blue: 0.35))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct SuccessContent: View {
    let result: VerificationResult
    let streakData: StreakData
    @State private var showAnimation = false

    var body: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.9, green: 0.95, blue: 0.9))
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.55, green: 0.75, blue: 0.55))
                    .scaleEffect(showAnimation ? 1.0 : 0.5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showAnimation)
            }

            Text("Bed Made!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

            // Score card
            VStack(spacing: 12) {
                Text("Score")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(result.score)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor(result.score))
                    Text("/10")
                        .font(.title2)
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
            .padding(.horizontal, 40)

            // Feedback
            Text(result.feedback)
                .font(.body)
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Streak badge
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(Color(red: 0.9, green: 0.6, blue: 0.4))
                Text("\(streakData.currentStreak) day streak!")
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 1.0, green: 0.95, blue: 0.9))
            .cornerRadius(20)
        }
        .onAppear {
            showAnimation = true
        }
    }

    func scoreColor(_ score: Int) -> Color {
        switch score {
        case 9...10: return Color(red: 0.4, green: 0.7, blue: 0.4)
        case 7...8: return Color(red: 0.5, green: 0.7, blue: 0.5)
        case 5...6: return Color(red: 0.8, green: 0.7, blue: 0.4)
        case 3...4: return Color(red: 0.85, green: 0.6, blue: 0.4)
        default: return Color(red: 0.8, green: 0.5, blue: 0.45)
        }
    }
}

struct FailureContent: View {
    let result: VerificationResult

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.98, green: 0.93, blue: 0.92))
                    .frame(width: 140, height: 140)

                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.85, green: 0.55, blue: 0.5))
            }

            Text("Not Quite...")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

            Text(result.feedback)
                .font(.body)
                .foregroundColor(Color(red: 0.5, green: 0.45, blue: 0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("Give it another try!")
                .font(.subheadline)
                .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
        }
    }
}

#Preview("Success") {
    ResultView()
        .environmentObject({
            let vm = BedVerificationViewModel()
            vm.lastResult = VerificationResult(isMade: true, score: 8, feedback: "Great job! Your bed looks neat and tidy.")
            return vm
        }())
}

#Preview("Failure") {
    ResultView()
        .environmentObject({
            let vm = BedVerificationViewModel()
            vm.lastResult = VerificationResult(isMade: false, score: 0, feedback: "The bed appears unmade. Try straightening the covers.")
            return vm
        }())
}

import SwiftUI

struct AnalyzingView: View {
    @State private var rotation: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Animated bed icon
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 160, height: 160)
                        .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 10)

                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color(red: 0.75, green: 0.65, blue: 0.55))
                        .scaleEffect(pulse ? 1.1 : 1.0)
                }

                VStack(spacing: 12) {
                    Text("Analyzing your bed...")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.35, green: 0.28, blue: 0.22))

                    Text("AI is checking if it's made")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.6, green: 0.5, blue: 0.4))
                }

                // Loading indicator
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(Color(red: 0.55, green: 0.45, blue: 0.35))

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    AnalyzingView()
}

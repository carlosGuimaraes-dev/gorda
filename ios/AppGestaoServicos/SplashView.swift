import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primary,
                                    AppTheme.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Text("AG")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 4) {
                    Text("AG Home Organizer International")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText)
                    Text("Service & team management")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
    }
}


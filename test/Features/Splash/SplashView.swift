//
//  SplashView.swift
//  test
//

import SwiftUI

/// Branded launch screen that runs `AppContainer.bootstrap()` then hands off to the router.
/// The static system launch screen is shown before this; keep their look consistent.
struct SplashView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthService.self) private var auth

    /// Launch work (session restore, entitlements…), injected from the composition root.
    let bootstrap: () async -> Void

    @State private var isAnimating = false

    private let minimumDuration: Duration = .seconds(1.2)

    var body: some View {
        VStack(spacing: Spacing.m) {
            Image(systemName: "sparkles")
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, value: isAnimating)
                .scaleEffect(isAnimating ? 1 : 0.8)

            Text("app.name")
                .font(.largeTitle.bold())
                .opacity(isAnimating ? 1 : 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .task {
            withAnimation(.spring(duration: 0.6)) { isAnimating = true }

            let start = ContinuousClock.now
            await bootstrap()
            let remaining = minimumDuration - (ContinuousClock.now - start)
            if remaining > .zero { try? await Task.sleep(for: remaining) }

            router.resolvePhase(isSignedIn: auth.isSignedIn)
        }
    }
}

#Preview {
    SplashView(bootstrap: {})
        .environment(AppContainer.preview)
}

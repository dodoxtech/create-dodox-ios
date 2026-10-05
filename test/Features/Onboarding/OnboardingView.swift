//
//  OnboardingView.swift
//  test
//

import SwiftUI

struct OnboardingPage: Identifiable {
    let id: Int
    let systemImage: String
    let title: LocalizedStringResource
    let message: LocalizedStringResource

    static let all: [OnboardingPage] = [
        .init(id: 0, systemImage: "sparkles", title: "onboarding.page1.title", message: "onboarding.page1.message"),
        .init(id: 1, systemImage: "chart.line.uptrend.xyaxis", title: "onboarding.page2.title", message: "onboarding.page2.message"),
        .init(id: 2, systemImage: "bell.badge", title: "onboarding.page3.title", message: "onboarding.page3.message"),
    ]
}

struct OnboardingView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AuthService.self) private var auth
    @Environment(AnalyticsService.self) private var analytics

    @State private var selection = 0
    private let pages = OnboardingPage.all

    private var isLastPage: Bool { selection == pages.count - 1 }

    var body: some View {
        VStack(spacing: Spacing.l) {
            HStack {
                Spacer()
                Button("onboarding.skip") { finish(skipped: true) }
                    .opacity(isLastPage ? 0 : 1)
            }
            .padding(.horizontal)

            TabView(selection: $selection) {
                ForEach(pages) { page in
                    pageView(page).tag(page.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if isLastPage {
                    finish(skipped: false)
                } else {
                    withAnimation { selection += 1 }
                }
            } label: {
                Text(isLastPage ? "onboarding.getStarted" : "onboarding.continue")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, Spacing.l)
        }
        .padding(.vertical)
        .trackScreen("onboarding")
        .onAppear { analytics.track(.onboardingStarted) }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: Spacing.l) {
            Image(systemName: page.systemImage)
                .font(.system(size: 96))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 160)

            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(page.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Spacing.xl)
    }

    private func finish(skipped: Bool) {
        analytics.track(.onboardingCompleted(skipped: skipped))
        router.completeOnboarding(isSignedIn: auth.isSignedIn)
    }
}

#Preview {
    OnboardingView()
        .environment(AppContainer.preview)
}

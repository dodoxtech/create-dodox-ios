//
//  AuthView.swift
//  test
//

import AuthenticationServices
import SwiftUI

struct AuthView: View {
    @Environment(AuthService.self) private var auth
    @Environment(AnalyticsService.self) private var analytics
    @Environment(\.colorScheme) private var colorScheme

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: Spacing.l) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: Spacing.s) {
                Text("auth.title")
                    .font(.largeTitle.bold())
                Text("auth.subtitle")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: Spacing.m) {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    signIn(method: "apple") { try await auth.handleAppleSignIn(result) }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .clipShape(.capsule)

                Button("auth.continueAsGuest") {
                    signIn(method: "guest") { try await auth.signInAsGuest() }
                }
                .font(.headline)
                .frame(minHeight: 44)
            }
            .disabled(isLoading)

            Text("auth.legal")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .tint(.secondary)
        }
        .padding(Spacing.l)
        .overlay {
            if isLoading { ProgressView().controlSize(.large) }
        }
        .errorAlert($errorMessage)
        .trackScreen("auth")
    }

    private func signIn(method: String, _ operation: @escaping () async throws -> Void) {
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await operation()
                analytics.track(.signInCompleted(method: method))
                analytics.identify(userID: auth.currentUser?.id)
            } catch let error as ASAuthorizationError where error.code == .canceled {
                // User dismissed the sheet – not an error.
            } catch {
                analytics.track(.signInFailed(method: method, reason: error.localizedDescription))
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(AppContainer.preview)
}

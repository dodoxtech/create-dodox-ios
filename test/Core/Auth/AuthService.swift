//
//  AuthService.swift
//  test
//

import AuthenticationServices
import Foundation
import OSLog
import Observation

struct AppUser: Codable, Equatable, Sendable {
    enum Provider: String, Codable, Sendable {
        case apple
        case guest
    }

    let id: String
    var displayName: String?
    var email: String?
    let provider: Provider
}

/// Exchanges a platform credential for an app session on your backend
/// (Firebase, Supabase, your own API…). `LocalAuthClient` keeps everything on-device.
protocol AuthClient {
    func signIn(withApple credential: ASAuthorizationAppleIDCredential) async throws -> AppUser
    func signInAsGuest() async throws -> AppUser
    func signOut(_ user: AppUser) async throws
    func deleteAccount(_ user: AppUser) async throws
}

struct LocalAuthClient: AuthClient {
    func signIn(withApple credential: ASAuthorizationAppleIDCredential) async throws -> AppUser {
        // TODO: Send `credential.identityToken` + `credential.authorizationCode` to your backend.
        // Apple only returns name/email on the *first* sign-in, so persist them server-side.
        let name = credential.fullName.flatMap {
            PersonNameComponentsFormatter.localizedString(from: $0, style: .default)
        }
        return AppUser(
            id: credential.user,
            displayName: name?.isEmpty == false ? name : nil,
            email: credential.email,
            provider: .apple
        )
    }

    func signInAsGuest() async throws -> AppUser {
        AppUser(id: "guest-\(UUID().uuidString)", displayName: nil, email: nil, provider: .guest)
    }

    func signOut(_ user: AppUser) async throws {}

    func deleteAccount(_ user: AppUser) async throws {
        // TODO: Delete server data and revoke the Apple token (App Store Review Guideline 5.1.1(v)).
    }
}

enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential: String(localized: "auth.error.invalidCredential")
        }
    }
}

/// Owns the current session. Views read `currentUser` / `isSignedIn`; the router reacts to changes.
@Observable
final class AuthService {
    private(set) var currentUser: AppUser?
    var isSignedIn: Bool { currentUser != nil }

    @ObservationIgnored private let client: any AuthClient
    @ObservationIgnored private let keychain: KeychainStore
    @ObservationIgnored private let sessionKey = "auth.session"

    init(client: any AuthClient = LocalAuthClient(), keychain: KeychainStore = KeychainStore()) {
        self.client = client
        self.keychain = keychain
    }

    /// Restores the persisted session and validates Apple credentials (they can be revoked in Settings).
    func restoreSession() async {
        guard let user = try? keychain.load(AppUser.self, for: sessionKey) else { return }

        if user.provider == .apple {
            let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: user.id)
            if state == .revoked || state == .notFound {
                Log.auth.notice("Apple credential no longer valid, clearing session")
                clearSession()
                return
            }
        }
        currentUser = user
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) async throws {
        let authorization = try result.get()
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }
        try persist(await client.signIn(withApple: credential))
    }

    func signInAsGuest() async throws {
        try persist(await client.signInAsGuest())
    }

    func signOut() async {
        if let currentUser { try? await client.signOut(currentUser) }
        clearSession()
    }

    func deleteAccount() async throws {
        guard let currentUser else { return }
        try await client.deleteAccount(currentUser)
        clearSession()
    }

    private func persist(_ user: AppUser) throws {
        try keychain.save(user, for: sessionKey)
        currentUser = user
        SharedStore.update { $0.userName = user.displayName }
    }

    private func clearSession() {
        try? keychain.delete(sessionKey)
        currentUser = nil
        SharedStore.update { $0.userName = nil }
    }
}

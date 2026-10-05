---
tags: [feature, auth]
status: done
updated: 2026-10-05
---

# Feature: Sign In

## Overview

Sign in with Apple or continue as guest. The session (`AppUser`) is stored in the Keychain and restored at
launch; a revoked Apple credential clears it. Sign-out and account deletion live in Settings. By default
everything is on-device (`LocalAuthClient`) — production apps plug a backend in through `AuthClient`.

## User Stories

- [x] Sign in with Apple (name + email requested)
- [x] Continue as guest without an account
- [x] Stay signed in across launches; get signed out if the Apple ID authorization is revoked
- [x] Sign out, or delete the account (with confirmation) from Settings

## Flow

```
AuthView ─ SignInWithAppleButton ─▶ auth.handleAppleSignIn(result) ─▶ client.signIn(withApple:) ─▶ persist
         └ "Continue as guest"   ─▶ auth.signInAsGuest()           ─▶ client.signInAsGuest()    ─▶ persist
persist = Keychain save + currentUser + SharedStore.userName  ─▶ RootView.onChange(isSignedIn) ─▶ .main
```

## Implementation

| File | Role |
|------|------|
| `test/Core/Auth/AuthService.swift` | `AppUser`, `AuthClient` protocol, `LocalAuthClient`, `AuthError`, `AuthService` |
| `test/Core/Auth/KeychainStore.swift` | Codable Keychain wrapper (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) |
| `test/Features/Auth/AuthView.swift` | UI, loading state, `.errorAlert` |

## Connecting a Backend

Implement `AuthClient` and inject it: `AuthService(client: MyAuthClient())` in `AppContainer`.

- Send `credential.identityToken` + `authorizationCode` to the server; Apple returns name/email **only on the
  first** authorization, so persist them server-side.
- `deleteAccount` must delete server data and revoke the Apple token (App Review Guideline 5.1.1(v)).

## Analytics

`sign_in_completed(method)`, `sign_in_failed(method, reason)`, `signed_out`, `account_deleted`; `identify(userID)` at launch.

## Known Limitations

- Guest IDs are random per sign-in; a guest who signs out loses that identity.
- No account linking (guest → Apple).

## Related

- [settings](settings.md) · [data-flow](../architecture/data-flow.md#persistence-map)

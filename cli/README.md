# create-dodox-ios

Create a SwiftUI iOS app (iOS 27) with the usual subscription-app building blocks already wired up:
Splash, Onboarding, Auth (Sign in with Apple), Home, Paywall & Subscription (StoreKit 2), Settings,
Analytics, Notifications, Localization (en / vi / ja) and a WidgetKit extension.

```bash
npx create-dodox-ios@latest
```

```
? App name › Baby Leveling
? Bundle ID (com.example.babyleveling) › com.dodoxtech.babyleveling
? Apple Team ID (optional) › ABCDE12345
? Deep link URL scheme (babyleveling) ›
✔ Created Baby Leveling in BabyLeveling
```

Non-interactive:

```bash
npx create-dodox-ios "Baby Leveling" --bundle-id com.dodoxtech.babyleveling --team ABCDE12345 --yes
```

| Option | Default |
|---|---|
| `--bundle-id <id>` | `com.example.<appname>` |
| `--team <id>` | empty (pick a team in Xcode → Signing & Capabilities) |
| `--url-scheme <scheme>` | `<appname>` |
| `-d, --directory <path>` | `./<AppName>` |
| `--no-git` | runs `git init` + initial commit |
| `-y, --yes` | prompts for anything not passed |

Requires Node.js 18+ and Xcode 27.

## Developing the template

The template is generated from the Xcode project at the repository root, which stays a normal, runnable app.

```bash
cd cli
npm run build-template          # root project → cli/template (placeholders)
node index.mjs "Demo App"       # try it locally
npm publish                     # rebuilds the template via `prepack`
```

`scripts/build-template.mjs` fails if any source identifier (bundle ID, Team ID, target name) would leak
into the template; update its `SOURCE` constants if you rename the root project.

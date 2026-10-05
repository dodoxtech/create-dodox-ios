---
tags: [feature, notifications]
status: done
updated: 2026-10-05
---

# Feature: Notifications

## Overview

`NotificationService` handles permission, APNs registration and local scheduling. `AppDelegate` is the
`UNUserNotificationCenterDelegate`: banners show in the foreground and a tap routes through the
`deepLink` payload.

## User Stories

- [x] Be asked for permission in context (Home card / Notification settings), never on first launch
- [x] Enable a daily reminder at a chosen time (default 20:00)
- [x] Jump to iOS Settings when permission was denied
- [x] Tap a notification to open the right screen

## Payload Contract

Every notification (local or remote) may carry `userInfo["deepLink"] = "testapp://<host>"`. Valid hosts are
the `DeepLink` cases — see [deep-links](deep-links.md).

```json
{ "aps": { "alert": { "title": "…", "body": "…" } }, "deepLink": "testapp://paywall" }
```

## Implementation

| File | Role |
|------|------|
| `test/Core/Notifications/NotificationService.swift` | `requestAuthorization`, `refreshStatus` (registers for APNs when authorized), daily reminder (`UNCalendarNotificationTrigger`), sample notification after 5 s |
| `test/App/AppDelegate.swift` | Token callbacks, `willPresent` (banner/list/sound), `didReceive` (analytics + `router.open`) |
| `test/Features/Settings/NotificationSettingsView.swift` | Permission state, reminder toggle + time picker |

Reminder settings persist in `StorageKey.dailyReminder*`; changing them reschedules immediately.

## TODO for Production

- Upload the APNs token in `didRegisterForRemoteNotifications(deviceToken:)` to your push provider.
- Switch `aps-environment` to production (handled by distribution signing).

## Analytics

`notification_permission(granted)`, `notification_opened(id)`, `screen_viewed(notification_settings)`.

## Related

- [deep-links](deep-links.md) · [settings](settings.md)

//
//  NotificationSettingsView.swift
//  test
//

import SwiftUI
import UIKit

struct NotificationSettingsView: View {
    @Environment(NotificationService.self) private var notifications
    @Environment(AnalyticsService.self) private var analytics
    @Environment(\.openURL) private var openURL

    var body: some View {
        @Bindable var notifications = notifications

        Form {
            switch notifications.authorizationStatus {
            case .notDetermined:
                Section {
                    Button("notifications.enable") {
                        Task {
                            let granted = await notifications.requestAuthorization()
                            analytics.track(.notificationPermission(granted: granted))
                        }
                    }
                } footer: {
                    Text("notifications.enable.footer")
                }
            case .denied:
                Section {
                    Button("notifications.openSettings") {
                        openURL(URL(string: UIApplication.openNotificationSettingsURLString)!)
                    }
                } footer: {
                    Text("notifications.denied.footer")
                }
            default:
                Section {
                    Toggle("notifications.dailyReminder", isOn: $notifications.isDailyReminderEnabled)
                    if notifications.isDailyReminderEnabled {
                        DatePicker("notifications.time", selection: reminderDate, displayedComponents: .hourAndMinute)
                    }
                }
            }
        }
        .navigationTitle("settings.notifications")
        .task { await notifications.refreshStatus() }
        .trackScreen("notification_settings")
    }

    /// Bridges `DateComponents` (hour/minute) to the `Date` that `DatePicker` expects.
    private var reminderDate: Binding<Date> {
        Binding {
            Calendar.current.date(from: notifications.reminderTime) ?? .now
        } set: { date in
            notifications.reminderTime = Calendar.current.dateComponents([.hour, .minute], from: date)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
    }
    .environment(AppContainer.preview)
}

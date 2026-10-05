//
//  SharedStore.swift
//  Shared (compiled into the app and the widget extension)
//

import Foundation

/// The data the app publishes for the widget to render.
nonisolated struct WidgetSnapshot: Codable, Equatable, Sendable {
    var userName: String?
    var isPremium: Bool
    var tapCount: Int
    var updatedAt: Date

    static let empty = WidgetSnapshot(userName: nil, isPremium: false, tapCount: 0, updatedAt: .distantPast)
    static let placeholder = WidgetSnapshot(userName: "Taio", isPremium: true, tapCount: 42, updatedAt: .now)
}

/// Reads and writes `WidgetSnapshot` in the App Group container.
nonisolated enum SharedStore {
    private static let key = "shared.widgetSnapshot"

    static func load(from defaults: UserDefaults = AppGroup.defaults) -> WidgetSnapshot {
        guard let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snapshot
    }

    static func save(_ snapshot: WidgetSnapshot, to defaults: UserDefaults = AppGroup.defaults) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func update(in defaults: UserDefaults = AppGroup.defaults, _ mutate: (inout WidgetSnapshot) -> Void) {
        var snapshot = load(from: defaults)
        mutate(&snapshot)
        snapshot.updatedAt = .now
        save(snapshot, to: defaults)
    }
}

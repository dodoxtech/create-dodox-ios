//
//  TestWidget.swift
//  TestWidget
//

import SwiftUI
import WidgetKit

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

/// Reads what the app published to the App Group. The app calls
/// `WidgetCenter.reloadTimelines(ofKind:)` whenever that data changes.
struct SnapshotProvider: TimelineProvider {
    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        let snapshot = context.isPreview ? .placeholder : SharedStore.load()
        completion(SnapshotEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let entry = SnapshotEntry(date: .now, snapshot: SharedStore.load())
        let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct TestWidgetEntryView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            Spacer()
            Text(entry.snapshot.tapCount, format: .number)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
            Text("widget.taps")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(DeepLink.home.url)
    }

    private var medium: some View {
        HStack {
            small
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                if let name = entry.snapshot.userName {
                    Text("widget.hello \(name)").font(.headline)
                }
                if entry.snapshot.isPremium {
                    Label("widget.premium", systemImage: "crown.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.yellow)
                } else {
                    Link(destination: DeepLink.paywall.url) {
                        Label("widget.upgrade", systemImage: "crown")
                            .font(.subheadline.bold())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "sparkles").foregroundStyle(.tint)
            Spacer()
            if entry.snapshot.isPremium {
                Image(systemName: "crown.fill").foregroundStyle(.yellow)
            }
        }
        .font(.headline)
    }
}

struct TestWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.main, provider: SnapshotProvider()) { entry in
            TestWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("widget.displayName")
        .description("widget.description")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TestWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
    SnapshotEntry(date: .now, snapshot: .empty)
}

#Preview(as: .systemMedium) {
    TestWidget()
} timeline: {
    SnapshotEntry(date: .now, snapshot: .placeholder)
}

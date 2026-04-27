import WidgetKit
import SwiftUI

// MARK: - Provider

struct FriendWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    static let placeholder = FriendWidgetEntry(date: Date(), snapshot: WidgetSnapshot(
        upcoming: [
            .init(personId: UUID(), firstName: "Alex", avatarHue: 22, label: "Birthday",
                  kind: .birthday, dateString: "May 14", daysAway: 20),
            .init(personId: UUID(), firstName: "Sam", avatarHue: 220, label: "Engagement party",
                  kind: .custom, dateString: "May 3", daysAway: 9),
        ],
        nudges: [
            .init(personId: UUID(), firstName: "Alex", avatarHue: 22,
                  suggestion: "Ask how the triathlon went"),
        ],
        updatedAt: Date()
    ))
}

struct FriendWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FriendWidgetEntry {
        FriendWidgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FriendWidgetEntry) -> Void) {
        completion(FriendWidgetEntry(date: Date(), snapshot: WidgetSnapshot.load() ?? FriendWidgetEntry.placeholder.snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FriendWidgetEntry>) -> Void) {
        let entry = FriendWidgetEntry(date: Date(), snapshot: WidgetSnapshot.load())
        // Refresh hourly — main app also calls reloadTimelines whenever it persists.
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

// MARK: - Views

struct FriendWidgetView: View {
    var entry: FriendWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:  smallView
            case .systemMedium: mediumView
            default:            smallView
            }
        }
        .containerBackground(Color.appBackground, for: .widget)
    }

    // ─── Small ─────────────────────────────────────────────────────────────
    private var smallView: some View {
        let upcoming = entry.snapshot?.upcoming.first
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: upcoming?.kind.iconName ?? "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.accent)
                Text(upcoming.map { "In \($0.daysAway)d" } ?? "—")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.55)
                    .foregroundStyle(Color.accent)
                    .textCase(.uppercase)
            }
            Spacer()
            if let upcoming {
                AvatarView(initials: initials(upcoming.firstName), hue: upcoming.avatarHue, size: 36)
                Text(upcoming.firstName)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.top, 8)
                Text("\(upcoming.label) · \(upcoming.dateString)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.muted)
            } else {
                emptySmall
            }
        }
        .widgetURL(upcoming.flatMap { URL(string: "friend://person/\($0.personId)") })
    }

    private var emptySmall: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No upcoming dates")
                .font(.system(size: 14, weight: .semibold))
            Text("Open Friend to add a few people.")
                .font(.system(size: 11))
                .foregroundStyle(Color.muted)
        }
    }

    // ─── Medium ────────────────────────────────────────────────────────────
    private var mediumView: some View {
        HStack(alignment: .top, spacing: 14) {
            upcomingColumn
            Divider().background(Color.hairline)
            nudgeColumn
        }
        .widgetURL(entry.snapshot?.nudges.first.map { URL(string: "friend://person/\($0.personId)")! }
                   ?? entry.snapshot?.upcoming.first.map { URL(string: "friend://person/\($0.personId)")! })
    }

    private var upcomingColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("UPCOMING").sectionLabel()
            if let upcoming = entry.snapshot?.upcoming, !upcoming.isEmpty {
                ForEach(upcoming.prefix(2), id: \.personId) { item in
                    HStack(spacing: 8) {
                        AvatarView(initials: initials(item.firstName), hue: item.avatarHue, size: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.firstName).font(.system(size: 12.5, weight: .semibold))
                            Text("\(item.label) · \(item.daysAway)d")
                                .font(.system(size: 10.5))
                                .foregroundStyle(Color.muted)
                        }
                    }
                }
            } else {
                Text("No upcoming")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.muted)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nudgeColumn: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NUDGES")
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.74)
                .foregroundStyle(Color.accent)
                .textCase(.uppercase)
            if let n = entry.snapshot?.nudges.first {
                AvatarView(initials: initials(n.firstName), hue: n.avatarHue, size: 28)
                Text(n.firstName)
                    .font(.system(size: 12.5, weight: .semibold))
                    .padding(.top, 6)
                Text(n.suggestion)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkSoft)
                    .lineLimit(3)
                    .lineSpacing(1)
            } else {
                Text("All caught up")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.muted)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

// MARK: - Widget

@main
struct FriendWidget: Widget {
    let kind: String = "FriendWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FriendWidgetProvider()) { entry in
            FriendWidgetView(entry: entry)
        }
        .configurationDisplayName("Friend")
        .description("Upcoming dates and reach-out nudges.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

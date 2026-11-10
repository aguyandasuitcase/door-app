import WidgetKit
import SwiftUI
import AppIntents

struct DoorEntry: TimelineEntry {
    let date: Date
    let lastVisitor: Date
    let lastEvent: VisitorEvent
}

struct DoorProvider: TimelineProvider {
    private var sample: DoorEntry {
        DoorEntry(
            date: Date(),
            lastVisitor: MockData.visitors().first?.date ?? Date(),
            lastEvent: .opened
        )
    }

    func placeholder(in context: Context) -> DoorEntry { sample }

    func getSnapshot(in context: Context, completion: @escaping (DoorEntry) -> Void) {
        completion(sample)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DoorEntry>) -> Void) {
        completion(Timeline(entries: [sample], policy: .after(Date().addingTimeInterval(1_800))))
    }
}

struct OpenDoorWidget: Widget {
    let kind = "OpenDoorWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DoorProvider()) { entry in
            OpenDoorWidgetView(entry: entry)
                .containerBackground(for: .widget) { WidgetBackground() }
        }
        .configurationDisplayName("Front door")
        .description("Open the door and see the last visitor.")
        .supportedFamilies([
            .systemSmall, .systemMedium,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

struct WidgetBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.12, green: 0.11, blue: 0.2), Color(red: 0.07, green: 0.07, blue: 0.12)]
                : [Color(red: 0.969, green: 0.957, blue: 0.937), Color(red: 0.910, green: 0.898, blue: 1.0)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct OpenDoorWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: DoorEntry

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemMedium: medium
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        case .accessoryInline: inline
        default: small
        }
    }

    private var openCircle: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 30))
            .foregroundStyle(.white)
            .frame(width: 72, height: 72)
            .background(Theme.violet.gradient, in: Circle())
    }

    private var small: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(Theme.mintBright).frame(width: 7, height: 7)
                Text("Front door").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
            }
            Spacer(minLength: 0)
            Button(intent: UnlockDoorIntent()) { openCircle }
                .buttonStyle(.plain)
            Text("Open door").font(.footnote.weight(.bold))
        }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(red: 0.655, green: 0.702, blue: 0.839), Color(red: 0.290, green: 0.337, blue: 0.514)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 120)
            VStack(alignment: .leading, spacing: 4) {
                Text("Last visitor").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(entry.lastVisitor, format: .dateTime.weekday(.abbreviated).hour().minute())
                    .font(.title3.bold())
                Text(entry.lastEvent.badge)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(entry.lastEvent.tint)
                Spacer(minLength: 0)
                Button(intent: UnlockDoorIntent()) {
                    Label("Open door", systemImage: "lock.open.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Theme.violet.gradient, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var circular: some View {
        Button(intent: UnlockDoorIntent()) {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "lock.open.fill").font(.title2)
            }
        }
        .buttonStyle(.plain)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Last visitor").font(.caption)
            Text(entry.lastVisitor, style: .time).font(.headline)
            Text(entry.lastEvent.badge).font(.caption2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label {
            Text("Last visitor \(entry.lastVisitor, style: .time)")
        } icon: {
            Image(systemName: "lock.fill")
        }
    }
}

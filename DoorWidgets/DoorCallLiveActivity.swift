import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct DoorCallLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DoorCallAttributes.self) { context in
            CallLockScreenView(context: context)
                .activityBackgroundTint(Color.white.opacity(0.65))
                .activitySystemActionForegroundColor(Theme.violet)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "bell.fill").font(.title2).foregroundStyle(Theme.violetSoft)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("\(context.attributes.stationName) is calling").font(.headline)
                        Text(context.state.status).font(.caption).foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 10) {
                        Link(destination: URL(string: "doorapp://answer")!) {
                            Text("Answer")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue, in: Capsule())
                        }
                        Button(intent: UnlockDoorIntent()) {
                            Label("Open door", systemImage: "lock.open.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Theme.mintBright, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                Image(systemName: "bell.fill").foregroundStyle(Theme.violetSoft)
            } compactTrailing: {
                Text("Door")
            } minimal: {
                Image(systemName: "bell.fill").foregroundStyle(Theme.violetSoft)
            }
        }
    }
}

struct CallLockScreenView: View {
    let context: ActivityViewContext<DoorCallAttributes>

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.655, green: 0.702, blue: 0.839), Color(red: 0.290, green: 0.337, blue: 0.514)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(context.attributes.stationName) is calling").font(.headline)
                    Text("\(context.attributes.stationCode) · \(context.state.status)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            HStack(spacing: 10) {
                Link(destination: URL(string: "doorapp://answer")!) {
                    Text("Answer")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue, in: Capsule())
                }
                Button(intent: UnlockDoorIntent()) {
                    Label("Open door", systemImage: "lock.open.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.mint, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }
}

import SwiftUI

struct LiveCard: View {
    @EnvironmentObject private var store: DoorStore
    var height: CGFloat

    private var isLive: Bool {
        if case .live = store.liveState { return true }
        return false
    }

    var body: some View {
        ZStack {
            CameraPlaceholder()
                .opacity(store.liveState == .off ? 0.55 : 1)
            switch store.liveState {
            case .off:
                Button { store.startLive() } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "play.fill").font(.system(size: 26))
                        Text("Tap to view").font(.footnote.weight(.semibold))
                    }
                    .frame(width: 112, height: 112)
                    .glassCircle()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start live view")
            case .connecting:
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Calling the door station").font(.footnote.weight(.semibold))
                }
                .padding(18)
                .glassCard(cornerRadius: 24)
            case .live(let left):
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Text("Preview only, no video yet")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .glassBackground(in: Capsule())
                        Spacer()
                        Text("\(left)s").font(.footnote.monospacedDigit().weight(.semibold))
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .glassBackground(in: Capsule())
                        RoundGlassButton(systemName: "speaker.wave.2.fill", label: "Speaker")
                        RoundGlassButton(systemName: "mic.fill", label: "Hold to talk")
                        Button { store.stopLive() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 17, weight: .semibold))
                                .frame(width: 44, height: 44)
                                .glassCircle()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Stop live view")
                    }
                    .padding(12)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            LiveChip(name: store.selectedStation.name, live: isLive).padding(12)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(8)
        .glassCard(cornerRadius: 36)
    }
}

/// Stand-in for the live video. Replace with the real video layer later.
struct CameraPlaceholder: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.655, green: 0.702, blue: 0.839),
                        Color(red: 0.459, green: 0.518, blue: 0.690),
                        Color(red: 0.290, green: 0.337, blue: 0.514)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.925, green: 0.937, blue: 0.984), Color(red: 0.718, green: 0.753, blue: 0.886)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: geo.size.width * 0.34, height: geo.size.height * 0.78)
                    .shadow(color: .white.opacity(0.35), radius: 40)
            }
        }
        .accessibilityHidden(true)
    }
}

struct LiveChip: View {
    var name: String
    var live: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(live ? Color.red : Color.gray).frame(width: 8, height: 8)
            Text(live ? "\(name) · Live" : "\(name) · Standby").font(.footnote.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassBackground(in: Capsule())
    }
}

struct RoundGlassButton: View {
    var systemName: String
    var label: String

    var body: some View {
        Button {
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 44, height: 44)
                .glassCircle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

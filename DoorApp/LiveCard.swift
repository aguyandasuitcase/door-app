import SwiftUI

struct LiveCard: View {
    @EnvironmentObject private var store: DoorStore
    @EnvironmentObject private var doorbells: DoorbellStore
    @ObservedObject private var sip = SIPService.shared
    var height: CGFloat

    /// The real call when the doorbell is connected, the demo otherwise.
    private var effective: LiveState {
        if sip.callActive { return .live(0) }
        if sip.calling { return .connecting }
        return store.liveState
    }

    private var isLive: Bool {
        if case .live = effective { return true }
        return false
    }

    private func start() {
        if sip.registered, let bell = doorbells.active,
           let station = bell.stations.first(where: { "DS\($0.index)" == store.selectedStationID }) {
            sip.startLive(station: station, bell: bell)
        } else {
            store.startLive()
        }
    }

    private func stop() {
        sip.hangUp()
        store.stopLive()
    }

    var body: some View {
        ZStack {
            CameraPlaceholder()
                .opacity(effective == .off ? 0.55 : 1)
            if sip.callActive { SIPVideoView() }
            switch effective {
            case .off:
                Button { start() } label: {
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
                        if !sip.callActive {
                            Text("Preview only, no video yet")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .glassBackground(in: Capsule())
                        }
                        Spacer()
                        if !sip.callActive {
                            Text("\(left)s").font(.footnote.monospacedDigit().weight(.semibold))
                                .padding(.horizontal, 10).padding(.vertical, 8)
                                .glassBackground(in: Capsule())
                        }
                        RoundGlassButton(systemName: "speaker.wave.2.fill", label: "Speaker")
                        RoundGlassButton(systemName: "mic.fill", label: "Hold to talk")
                        Button { stop() } label: {
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
        .overlay(alignment: .bottom) {
            if sip.incoming {
                HStack(spacing: 12) {
                    Button { sip.decline() } label: {
                        Label("Decline", systemImage: "phone.down.fill")
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color.red, in: Capsule()).foregroundStyle(.white)
                    }
                    Button { sip.answer() } label: {
                        Label("Answer", systemImage: "phone.fill")
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color.green, in: Capsule()).foregroundStyle(.white)
                    }
                }
                .padding(12)
            }
        }
        .overlay(alignment: .topLeading) {
            Menu {
                ForEach(store.stations) { station in
                    Button {
                        store.select(station)
                    } label: {
                        if station.id == store.selectedStationID {
                            Label(station.name, systemImage: "checkmark")
                        } else {
                            Text(station.name)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    LiveChip(name: store.selectedStation.name, live: isLive)
                    if store.stations.count > 1 {
                        Image(systemName: "chevron.down").font(.caption2.weight(.bold)).foregroundStyle(.white)
                    }
                }
            }
            .disabled(store.stations.count < 2)
            .padding(12)
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

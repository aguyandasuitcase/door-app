import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: DoorStore
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        NavigationStack {
            ScrollView {
                if sizeClass == .regular { regular } else { compact }
            }
            .scrollIndicators(.hidden)
            .background(AppBackground())
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ConnectionChip(state: store.connection)
                }
            }
        }
    }

    private var compact: some View {
        VStack(spacing: 24) {
            LiveCard(height: 190)
            OrbPanel(orbSize: 200)
            VisitorsSection(limit: 2)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    private var regular: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 24) {
                LiveCard(height: 460)
                StationsRow()
            }
            VStack(spacing: 24) {
                OrbPanel(orbSize: 210)
                    .padding(.vertical, 28)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 40)
                VisitorsSection(limit: 4)
            }
            .frame(width: 400)
        }
        .padding(24)
    }
}

struct OrbPanel: View {
    @EnvironmentObject private var store: DoorStore
    @AppStorage("holdToOpen") private var holdToOpen = true
    var orbSize: CGFloat

    private var title: String {
        switch store.unlockState {
        case .idle: return holdToOpen ? "Hold to open" : "Tap to open"
        case .unlocking: return "Opening…"
        case .unlocked: return "Door unlocked"
        case .failed: return "Could not open"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HoldToOpenOrb(
                state: store.unlockState,
                size: orbSize,
                holdDuration: holdToOpen ? 0.9 : 0.05
            ) {
                store.beginUnlock()
            }
            Text(title)
                .font(.title3.bold())
            Text("Unlock 1 · \(store.selectedStation.name)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct ConnectionChip: View {
    var state: ConnectionState

    private var text: String {
        switch state {
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .offline: return "Offline"
        }
    }

    private var color: Color {
        switch state {
        case .connecting: return .orange
        case .connected: return Theme.mint
        case .offline: return Theme.alert
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).font(.footnote.weight(.semibold)).foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.14), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

struct StationsRow: View {
    @EnvironmentObject private var store: DoorStore

    var body: some View {
        HStack(spacing: 16) {
            ForEach(store.stations.filter { $0.id != store.selectedStationID }.prefix(3)) { station in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.725, green: 0.765, blue: 0.886), Color(red: 0.486, green: 0.537, blue: 0.722)],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: 76, height: 76)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(station.name).font(.headline)
                        Label("Online", systemImage: "circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.mint)
                    }
                    Spacer(minLength: 0)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .glassCard(cornerRadius: 28)
                .accessibilityElement(children: .combine)
            }
        }
    }
}

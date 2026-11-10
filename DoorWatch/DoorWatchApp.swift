import SwiftUI

@main
struct DoorWatchApp: App {
    @StateObject private var store = DoorStore()

    var body: some Scene {
        WindowGroup {
            WatchRoot()
                .environmentObject(store)
                .tint(Theme.violetSoft)
        }
    }
}

struct WatchRoot: View {
    var body: some View {
        TabView {
            WatchOrbView()
            WatchLastVisitorView()
            WatchCallView()
        }
        .tabViewStyle(.verticalPage)
    }
}

struct WatchOrbView: View {
    @EnvironmentObject private var store: DoorStore

    private var title: String {
        switch store.unlockState {
        case .idle: return "Hold to open"
        case .unlocking: return "Opening…"
        case .unlocked: return "Door unlocked"
        case .failed: return "Could not open"
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(store.selectedStation.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            HoldToOpenOrb(state: store.unlockState, size: 124) {
                store.beginUnlock()
            }
            Text(title).font(.headline)
        }
    }
}

struct WatchLastVisitorView: View {
    @EnvironmentObject private var store: DoorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let last = store.visitors.first {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.769, green: 0.800, blue: 0.910), Color(red: 0.529, green: 0.576, blue: 0.761)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)
                        .overlay(Image(systemName: "person.fill").foregroundStyle(.white))
                    VStack(alignment: .leading) {
                        Text("Last visitor").font(.caption).foregroundStyle(.secondary)
                        Text(last.date, format: .dateTime.weekday(.abbreviated).hour().minute())
                            .font(.headline)
                    }
                }
            }
            Button {
                store.beginUnlock()
            } label: {
                Label("Open door", systemImage: "lock.open.fill")
                    .frame(maxWidth: .infinity)
            }
            .tint(Theme.violetSoft)
        }
        .padding(.horizontal, 4)
    }
}

struct WatchCallView: View {
    @EnvironmentObject private var store: DoorStore

    var body: some View {
        VStack(spacing: 8) {
            VStack(spacing: 2) {
                Text(store.selectedStation.name).font(.headline)
                Text("Calling").font(.caption).foregroundStyle(.secondary)
            }
            Button {
            } label: {
                Text("Answer").frame(maxWidth: .infinity)
            }
            .tint(.blue)
            Button {
                store.beginUnlock()
            } label: {
                Label("Open door", systemImage: "lock.open.fill")
                    .frame(maxWidth: .infinity)
            }
            .tint(Theme.mintBright)
        }
    }
}

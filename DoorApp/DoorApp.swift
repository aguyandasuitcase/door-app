import SwiftUI
import AppIntents

@main
struct DoorApp: App {
    @StateObject private var store = DoorStore()
    @StateObject private var doorbells = DoorbellStore()

    init() {
        NotificationManager.shared.setUp()
        KeepAlive.shared.resumeIfWanted()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(doorbells)
                .tint(Theme.violet)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: DoorStore
    @EnvironmentObject private var doorbells: DoorbellStore

    private func syncStations() {
        guard let bell = doorbells.active, !bell.stations.isEmpty else { return }
        let active = bell.stations.filter(\.enabled)
        let shown = active.isEmpty ? Array(bell.stations.prefix(1)) : active
        store.setStations(shown.sorted { $0.index < $1.index }.map {
            DoorStation(id: "DS\($0.index)", name: $0.name, code: $0.name, isOnline: true)
        })
    }

    private func connect() {
        guard UserDefaults.standard.object(forKey: "autoConnect") as? Bool ?? true,
              let bell = doorbells.active else { return }
        SIPService.shared.register(bell)
    }

    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") { HomeView() }
            Tab("History", systemImage: "clock.fill") { HistoryView() }
            Tab("Settings", systemImage: "gearshape.fill") { SettingsView() }
        }
        .tabViewStyle(.sidebarAdaptable)
        .onAppear { syncStations(); connect() }
        .onChange(of: doorbells.active) { _, _ in syncStations(); connect() }
    }
}

struct DoorShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: UnlockDoorIntent(),
            phrases: [
                "Open the front door in \(.applicationName)",
                "Open door with \(.applicationName)"
            ],
            shortTitle: "Open door",
            systemImageName: "lock.open.fill"
        )
    }
}

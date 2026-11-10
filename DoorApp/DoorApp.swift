import SwiftUI
import AppIntents

@main
struct DoorApp: App {
    @StateObject private var store = DoorStore()
    @StateObject private var doorbells = DoorbellStore()

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
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") { HomeView() }
            Tab("History", systemImage: "clock.fill") { HistoryView() }
            Tab("Settings", systemImage: "gearshape.fill") { SettingsView() }
        }
        .tabViewStyle(.sidebarAdaptable)
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

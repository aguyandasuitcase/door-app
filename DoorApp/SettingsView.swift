import SwiftUI
import ActivityKit

struct SettingsView: View {
    @EnvironmentObject private var store: DoorStore
    @EnvironmentObject private var doorbells: DoorbellStore
    @AppStorage("holdToOpen") private var holdToOpen = true
    @AppStorage("saveSnapshots") private var saveSnapshots = true
    @AppStorage("notifyMissed") private var notifyMissed = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Doorbells") {
                    NavigationLink {
                        DoorbellsView()
                    } label: {
                        LabeledContent("Doorbells", value: doorbells.active?.name ?? "Add one")
                    }
                }
                Section("Door") {
                    Picker("Main door station", selection: $store.selectedStationID) {
                        ForEach(store.stations) { Text($0.name).tag($0.id) }
                    }
                    LabeledContent("Default unlock", value: "Unlock 1")
                }
                Section("Opening") {
                    Toggle("Hold to open gesture", isOn: $holdToOpen)
                }
                Section("Security") {
                    Text("Widgets, Controls, Siri and the Action Button always ask for Face ID or your passcode before the door opens.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Visitors") {
                    Toggle("Save visitor snapshots", isOn: $saveSnapshots)
                    Toggle("Notify on missed calls", isOn: $notifyMissed)
                }
                Section("Notifications") {
                    Button("Allow notifications") {
                        Task { _ = await NotificationManager.shared.requestPermission() }
                    }
                    Button("Send test ring in 5 seconds") {
                        NotificationManager.shared.postRing(station: store.selectedStation.name, after: 5)
                    }
                    Text("Lock the phone after tapping to see how a ring looks. These are local notifications, so a real ring while the app is closed needs the SIP connection or a push relay.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Testing") {
                    Button("Preview incoming call") {
                        CallActivityController.startDemo()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("Settings")
        }
    }
}

enum CallActivityController {
    static func startDemo() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = DoorCallAttributes(stationName: "Front door", stationCode: "DT-DS1")
        let state = DoorCallAttributes.ContentState(status: "Ringing")
        _ = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    }
}

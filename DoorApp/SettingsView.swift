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

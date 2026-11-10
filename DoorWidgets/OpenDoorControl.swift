import WidgetKit
import SwiftUI
import AppIntents

/// Control Center and Lock Screen control. Can also be assigned to the Action Button.
struct OpenDoorControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "OpenDoorControl") {
            ControlWidgetButton(action: UnlockDoorIntent()) {
                Label("Front door", systemImage: "lock.open.fill")
            }
        }
        .displayName("Open front door")
        .description("Unlocks the front door after Face ID.")
    }
}

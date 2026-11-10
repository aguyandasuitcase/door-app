import AppIntents
import ActivityKit

/// Used by widgets, Control Center, the Action Button, Siri and Live Activities.
/// The system asks for Face ID or the passcode before it runs.
struct UnlockDoorIntent: AppIntent {
    static let title: LocalizedStringResource = "Open front door"
    static let description = IntentDescription("Unlocks the front door.")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static let openAppWhenRun = false

    func perform() async throws -> some IntentResult {
        try await MockDoorService().unlock(stationID: "DS1", relay: 1)
        return .result()
    }
}

struct DoorCallAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var status: String
    }

    var stationName: String
    var stationCode: String
}

import SwiftUI

/// Talks to the real intercom. Today only a mock exists; a SIP-backed
/// implementation will replace it once the doorbell details are confirmed.
protocol DoorServing: Sendable {
    func unlock(stationID: String, relay: Int) async throws
}

struct MockDoorService: DoorServing {
    func unlock(stationID: String, relay: Int) async throws {
        try await Task.sleep(for: .milliseconds(600))
    }
}

@MainActor
final class DoorStore: ObservableObject {
    @Published var stations = MockData.stations
    @Published var visitors = MockData.visitors()
    @Published var selectedStationID = "DS1"
    @Published var connection: ConnectionState = .connected
    @Published var unlockState: UnlockState = .idle

    private let service: DoorServing

    init(service: DoorServing = MockDoorService()) {
        self.service = service
    }

    var selectedStation: DoorStation {
        stations.first { $0.id == selectedStationID } ?? stations[0]
    }

    func beginUnlock(relay: Int = 1) {
        guard unlockState != .unlocking else { return }
        unlockState = .unlocking
        let stationID = selectedStationID
        Task {
            do {
                try await service.unlock(stationID: stationID, relay: relay)
                unlockState = .unlocked
                visitors.insert(
                    Visitor(id: UUID(), date: Date(), event: .opened, stationID: stationID),
                    at: 0
                )
            } catch {
                unlockState = .failed(error.localizedDescription)
            }
            try? await Task.sleep(for: .seconds(3))
            unlockState = .idle
        }
    }
}

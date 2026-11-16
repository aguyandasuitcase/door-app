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

enum LiveState: Equatable {
    case off, connecting, live(Int)
}

@MainActor
final class DoorStore: ObservableObject {
    @Published var stations = MockData.stations
    @Published var visitors = MockData.visitors()
    @Published var selectedStationID = "DS1"
    @Published var connection: ConnectionState = .connected
    @Published var unlockState: UnlockState = .idle
    @Published var liveState: LiveState = .off
    private var liveTask: Task<Void, Never>?

    private let service: DoorServing

    init(service: DoorServing = MockDoorService()) {
        self.service = service
    }

    var selectedStation: DoorStation {
        stations.first { $0.id == selectedStationID } ?? stations[0]
    }

    /// Opens the monitoring call to the door station. Today this only simulates it.
    func startLive(seconds: Int = 60) {
        guard liveState == .off else { return }
        liveState = .connecting
        liveTask = Task {
            try? await Task.sleep(for: .seconds(1))
            var left = seconds
            while left > 0 && !Task.isCancelled {
                liveState = .live(left)
                try? await Task.sleep(for: .seconds(1))
                left -= 1
            }
            liveState = .off
        }
    }

    func stopLive() {
        liveTask?.cancel()
        liveTask = nil
        liveState = .off
    }

    /// Replaces the station list, for example after a doorbell QR was added or switched.
    func setStations(_ list: [DoorStation]) {
        guard !list.isEmpty else { return }
        stations = list
        if !list.contains(where: { $0.id == selectedStationID }) {
            selectedStationID = list[0].id
            stopLive()
        }
    }

    func select(_ station: DoorStation) {
        guard station.id != selectedStationID else { return }
        stopLive()
        selectedStationID = station.id
    }

    func clearHistory() {
        visitors.removeAll()
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

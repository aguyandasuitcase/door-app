import SwiftUI

struct DoorStation: Identifiable, Hashable {
    let id: String
    var name: String
    var code: String
    var isOnline: Bool
}

enum VisitorEvent: String, CaseIterable, Identifiable {
    case opened, missed, answered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .opened: return "Visitor at the door"
        case .missed: return "Missed call"
        case .answered: return "Answered call"
        }
    }

    var badge: String {
        switch self {
        case .opened: return "Opened"
        case .missed: return "Missed"
        case .answered: return "Answered"
        }
    }

    var tint: Color {
        switch self {
        case .opened, .answered: return Theme.mint
        case .missed: return Theme.alert
        }
    }
}

struct Visitor: Identifiable, Hashable {
    let id: UUID
    var date: Date
    var event: VisitorEvent
    var stationID: String
}

enum ConnectionState {
    case connecting, connected, offline
}

enum UnlockState: Equatable {
    case idle, unlocking, unlocked, failed(String)
}

enum MockData {
    static let stations: [DoorStation] = [
        DoorStation(id: "DS1", name: "Front door", code: "DT-DS1", isOnline: true),
        DoorStation(id: "DS2", name: "Station 2", code: "DT-DS2", isOnline: true),
        DoorStation(id: "DS3", name: "Station 3", code: "DT-DS3", isOnline: true),
        DoorStation(id: "DS4", name: "Station 4", code: "DT-DS4", isOnline: true)
    ]

    static func visitors() -> [Visitor] {
        let day: TimeInterval = 86_400
        let entries: [(TimeInterval, VisitorEvent)] = [
            (day * 1 + 3_600, .opened),
            (day * 2 + 600, .missed),
            (day * 4 + 7_200, .opened),
            (day * 6 + 1_800, .opened),
            (day * 7 + 5_400, .missed),
            (day * 9 + 900, .opened),
            (day * 12 + 4_000, .opened),
            (day * 15 + 2_000, .missed)
        ]
        return entries.map { offset, event in
            Visitor(id: UUID(), date: Date(timeIntervalSinceNow: -offset), event: event, stationID: "DS1")
        }
    }
}

import CoreLocation
import Foundation

/// Keeps the app running in the background using low-power location updates,
/// so a SIP connection can stay registered without push notifications.
/// Position is never read or stored. Significant-change monitoring also
/// relaunches the app if iOS has ended it.
@MainActor
final class KeepAlive: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = KeepAlive()

    @Published private(set) var status: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isRunning = false

    private let manager = CLLocationManager()
    private let key = "keepAlive"

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 3_000
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = false
        status = manager.authorizationStatus
    }

    var wantsKeepAlive: Bool { UserDefaults.standard.bool(forKey: key) }

    /// Call at app launch to resume after a relaunch.
    func resumeIfWanted() {
        if wantsKeepAlive { enable() }
    }

    func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: key)
        on ? enable() : disable()
    }

    private func enable() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.requestAlwaysAuthorization()
            start()
        case .authorizedAlways:
            start()
        default:
            break
        }
    }

    private func start() {
        manager.allowsBackgroundLocationUpdates = true
        manager.startUpdatingLocation()
        manager.startMonitoringSignificantLocationChanges()
        isRunning = true
    }

    private func disable() {
        manager.stopUpdatingLocation()
        manager.stopMonitoringSignificantLocationChanges()
        manager.allowsBackgroundLocationUpdates = false
        isRunning = false
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.status = manager.authorizationStatus
            if self.wantsKeepAlive { self.enable() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

import Combine
import CoreLocation
import Foundation

/// A base class to handle common location services logic like authorization and fetching the user's current position.
@available(macOS 14.0, iOS 15.0, *)
open class BaseLocationHelper: NSObject, ObservableObject, CLLocationManagerDelegate {

    /// The underlying CLLocationManager instance.
    public let manager = CLLocationManager()

    /// The most recently fetched location coordinate.
    @Published public var currentLocation: CLLocationCoordinate2D?

    /// The current authorization status for location services.
    @Published public var authorizationStatus: CLAuthorizationStatus

    public override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Requests the appropriate location authorization based on the platform and current status.
    public func requestAuthorization() {
        switch manager.authorizationStatus {
        case .notDetermined:
            #if os(iOS)
                manager.requestWhenInUseAuthorization()
            #elseif os(macOS)
                manager.requestAlwaysAuthorization()
            #endif
        #if os(iOS)
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
        #else
            case .authorizedAlways:
                manager.startUpdatingLocation()
        #endif
        default:
            break
        }
    }

    /// Triggers a single location request.
    public func fetchCurrentLocation() {
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = locations.last?.coordinate
    }

    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus = status
        #if os(iOS)
            let isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
        #else
            let isAuthorized = status == .authorizedAlways
        #endif

        if isAuthorized {
            manager.startUpdatingLocation()
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with error: \(error.localizedDescription)")
    }
}

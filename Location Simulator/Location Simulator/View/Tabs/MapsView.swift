//
//  MapsView.swift
//  Location Simulator
//
//  Created by Bandan.K on 07/11/25.
//

import MapKit
import SwiftUI

struct MapsView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()
                .onAppear {
                    locationManager.requestLocation()
                }
                .onReceive(locationManager.$currentLocation.dropFirst().compactMap { $0 }) { userCoordinate in
                    updateRegion(to: userCoordinate)
                }

            Button(action: focusOnUser) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 30))
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
            .padding()
        }
    }

    private func updateRegion(to userCoordinate: CLLocationCoordinate2D) {
        region.center = userCoordinate
    }

    /// Focuses the map on the user's current location.
    private func focusOnUser() {
        guard let userCoordinate = locationManager.currentLocation else { return }
        updateRegion(to: userCoordinate)
    }
}

/// A manager responsible for handling location permissions and updates.
///
/// This class encapsulates `CLLocationManager` logic and publishes the user's current coordinate.
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 1  // Update even for 1 meter movement
    }

    /// Requests location authorization from the user if not already granted and starts location updates.
    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined, .denied, .restricted:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error.localizedDescription)
    }
}

#Preview {
    MapsView()
}

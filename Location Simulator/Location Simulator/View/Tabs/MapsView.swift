//
//  MapsView.swift
//  Location Simulator
//
//  Created by Bandan.K on 07/11/25.
//

import MapKit
import SwiftUI
import LocationHelperCore

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
/// This class leverages `BaseLocationHelper` from the shared core package.
final class LocationManager: BaseLocationHelper {

    /// Requests location authorization from the user.
    func requestLocation() {
        requestAuthorization()
    }
}

#Preview {
    MapsView()
}

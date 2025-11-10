//
//  MapsView.swift
//  Location Simulator
//
//  Created by Bandan.K on 07/11/25.
//

import SwiftUI
import MapKit

struct MapsView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090), // fallback (Apple HQ)
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()
                .onAppear {
                    locationManager.requestLocation()
                }
                .onReceive(locationManager.$currentLocation.compactMap { $0 }) { coordinate in
                    region.center = coordinate
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


    private func focusOnUser() {
        guard let userCoordinate = locationManager.currentLocation else { return }
        region = MKCoordinateRegion(
            center: userCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
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
        }
    }
}

#Preview {
    MapsView()
}

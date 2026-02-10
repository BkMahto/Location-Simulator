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
    @StateObject private var locationManager = BaseLocationHelper()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea()

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
        .task {
            locationManager.requestAuthorization()
        }
        .onReceive(locationManager.$currentLocation.dropFirst().compactMap { $0 }) { userCoordinate in
            updateRegion(to: userCoordinate)
        }
    }

    private func updateRegion(to userCoordinate: CLLocationCoordinate2D) {
        region.center = userCoordinate
    }

    private func focusOnUser() {
        guard let userCoordinate = locationManager.currentLocation else { return }
        updateRegion(to: userCoordinate)
    }
}

#Preview {
    MapsView()
}

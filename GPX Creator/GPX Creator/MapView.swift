//
//  MapView.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import SwiftUI
import MapKit

struct MapView: NSViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedStartLocation: CLLocationCoordinate2D?
    @Binding var selectedEndLocation: CLLocationCoordinate2D?
    @Binding var isPathMode: Bool
    @Binding var route: MKRoute?
    @Binding var isCalculatingRoute: Bool
    @Binding var startAddress: String
    @Binding var endAddress: String
    @Binding var singleAddress: String
    @Binding var isTwoFieldMode: Bool
    @Binding var suppressStartSearch: Bool
    @Binding var suppressEndSearch: Bool
    @Binding var suppressSingleSearch: Bool
    @Binding var isSearchingStart: Bool
    @Binding var isSearchingEnd: Bool
    @Binding var isSearchingSingle: Bool

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none

        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        mapView.addGestureRecognizer(click)

        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        // Only update region if it's significantly different to avoid snapping back
        let current = mapView.region
        let new = region
        let centerDeltaLat = abs(current.center.latitude - new.center.latitude)
        let centerDeltaLon = abs(current.center.longitude - new.center.longitude)
        let spanDeltaLat = abs(current.span.latitudeDelta - new.span.latitudeDelta)
        let spanDeltaLon = abs(current.span.longitudeDelta - new.span.longitudeDelta)
        let needsUpdate = centerDeltaLat > 0.0005 || centerDeltaLon > 0.0005 || spanDeltaLat > 0.0005 || spanDeltaLon > 0.0005
        if needsUpdate {
            mapView.setRegion(region, animated: true)
        }

        // Clear existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Add start location annotation
        if let startLocation = selectedStartLocation {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = startLocation
            startAnnotation.title = "Start"
            mapView.addAnnotation(startAnnotation)
        }

        // Add end location annotation
        if let endLocation = selectedEndLocation {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = endLocation
            endAnnotation.title = "End"
            mapView.addAnnotation(endAnnotation)
        }

        // Add route polyline if available
        if let route = route {
            mapView.addOverlay(route.polyline)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            // Handle annotation selection if needed
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard parent.isPathMode, let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            // Decide upfront which field to target to avoid race with geocoder
            let isSettingStart = (parent.selectedStartLocation == nil)

            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                if let p = placemarks?.first {
                    // Build a concise address/title from CLPlacemark components
                    let parts: [String] = [
                        p.name,
                        p.locality,
                        p.administrativeArea,
                    ].compactMap { $0 }
                    let title = parts.first ?? "Selected Location"
                    DispatchQueue.main.async {
                        if self.parent.isTwoFieldMode {
                            if isSettingStart {
                                self.parent.startAddress = title
                                self.parent.suppressStartSearch = true
                                self.parent.isSearchingStart = false
                            } else {
                                self.parent.endAddress = title
                                self.parent.suppressEndSearch = true
                                self.parent.isSearchingEnd = false
                            }
                        } else {
                            self.parent.singleAddress = title
                            self.parent.suppressSingleSearch = true
                            self.parent.isSearchingSingle = false
                        }
                    }
                }
            }

            if parent.selectedStartLocation == nil {
                parent.selectedStartLocation = coordinate
            } else if parent.selectedEndLocation == nil {
                parent.selectedEndLocation = coordinate
                parent.isPathMode = false
            }
            // Do not force recenter; keep current camera
        }
    }
}

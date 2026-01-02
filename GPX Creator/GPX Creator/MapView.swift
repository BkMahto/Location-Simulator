//
//  MapView.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import SwiftUI
import MapKit

struct MapView: NSViewRepresentable {
    @ObservedObject var viewModel: GPXCreatorViewModel

    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none

        // Add click gesture recognizer with proper configuration
        let click = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        click.numberOfClicksRequired = 1
        click.numberOfTouchesRequired = 1
        // Don't cancel other gestures - allow coexistence with map gestures
        click.delaysPrimaryMouseButtonEvents = false
        click.delaysSecondaryMouseButtonEvents = false
        mapView.addGestureRecognizer(click)

        return mapView
    }

    func updateNSView(_ mapView: MKMapView, context: Context) {
        // Only update region if it's significantly different to avoid snapping back
        let current = mapView.region
        let new = viewModel.appState.region
        let centerDeltaLat = abs(current.center.latitude - new.center.latitude)
        let centerDeltaLon = abs(current.center.longitude - new.center.longitude)
        let spanDeltaLat = abs(current.span.latitudeDelta - new.span.latitudeDelta)
        let spanDeltaLon = abs(current.span.longitudeDelta - new.span.longitudeDelta)
        let needsUpdate = centerDeltaLat > 0.0001 || centerDeltaLon > 0.0001 || spanDeltaLat > 0.001 || spanDeltaLon > 0.001
        if needsUpdate {
            mapView.setRegion(viewModel.appState.region, animated: true)
        }

        // Clear existing annotations and overlays
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)

        // Add start location annotation
        if let startLocation = viewModel.appState.selectedStartLocation {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = startLocation
            startAnnotation.title = "Start"
            mapView.addAnnotation(startAnnotation)
        }

        // Add end location annotation
        if let endLocation = viewModel.appState.selectedEndLocation {
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = endLocation
            endAnnotation.title = "End"
            mapView.addAnnotation(endAnnotation)
        }

        // Add route polyline if available
        if let route = viewModel.appState.route {
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
            guard let mapView = gesture.view as? MKMapView else { return }

            let point = gesture.location(in: mapView)

            // Check if the click was on an annotation view
            for annotation in mapView.annotations {
                if mapView.view(for: annotation) != nil {
                    let annotationPoint = mapView.convert(annotation.coordinate, toPointTo: mapView)
                    let annotationRect = CGRect(x: annotationPoint.x - 20, y: annotationPoint.y - 20, width: 40, height: 40)

                    if annotationRect.contains(point) {
                        // Click was on an annotation, let the map handle it
                        return
                    }
                }
            }

            // Click was on empty map space, handle point selection
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            // Handle the map click through the view model
            // Always allow clicking to select points, regardless of path mode
            parent.viewModel.handleMapClick(at: coordinate)
        }
    }
}

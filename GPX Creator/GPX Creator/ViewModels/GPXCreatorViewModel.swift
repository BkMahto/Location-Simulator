//
//  GPXCreatorViewModel.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import Foundation
import MapKit
import Combine
import SwiftUI
import CoreLocation

@MainActor
class GPXCreatorViewModel: NSObject, ObservableObject {
    // MARK: - Published State
    @Published var appState = AppState()
    @Published var searchState = SearchState()
    @Published var exportState = ExportState()
    @Published var errorState = ErrorState()

    // MARK: - Private Properties
    private var searchTasks = [String: Task<Void, Never>]()
    private let geocoder = CLGeocoder()
    private let locationSearch = MKLocalSearch.self
    private var geocodeCache = [CoordinateKey: String]()
    private let geocodeCacheLimit = 50
    private let locationManager = CLLocationManager()

    // MARK: - Supporting Types

    private struct CoordinateKey: Hashable {
        let latitude: Double
        let longitude: Double

        init(_ coordinate: CLLocationCoordinate2D) {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }
    }

    // MARK: - Constants
    private let maxSimulationSpeed: Double = 100
    private let minSimulationSpeed: Double = 20
    private let searchDebounceDelay: TimeInterval = 0.5

    // MARK: - Initialization
    override init() {
        super.init()
        setupInitialState()
    }

    private func setupInitialState() {
        // Start with fallback location
        let fallbackCoordinate = CLLocationCoordinate2D(latitude: 22.47769553, longitude: 70.0467413)
        appState.region = MKCoordinateRegion(
            center: fallbackCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )

        // Request user's current location
        requestUserLocation()
    }

    private func requestUserLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self

        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorized, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            locationManager.requestWhenInUseAuthorization()
            // Use fallback location (already set in setupInitialState)
            break
        @unknown default:
            break
        }
    }

    // MARK: - Public Methods

    func updateSimulationSpeed(_ newSpeed: Double) {
        let validatedSpeed = max(minSimulationSpeed, min(maxSimulationSpeed, newSpeed))
        let roundedSpeed = round(validatedSpeed / 10) * 10

        if appState.simulationSpeed != roundedSpeed {
            appState.simulationSpeed = roundedSpeed

            if validatedSpeed != newSpeed {
                showWarning(.simulationSpeedAdjusted)
            }
        }
    }

    func toggleTwoFieldMode() {
        appState.isTwoFieldMode.toggle()

        // Handle mode switching logic
        if appState.isTwoFieldMode {
            // Switching TO two-field mode
            // Transfer single address to start address if switching from single mode
            if !searchState.startAddress.isEmpty {
                // Keep the start address as is
            }
        } else {
            // Switching FROM two-field mode TO single-field mode
            // Remove start location, keep end location as the single location
            if appState.selectedStartLocation != nil {
                if !searchState.endAddress.isEmpty {
                    searchState.startAddress = searchState.endAddress
                    appState.selectedStartLocation = appState.selectedEndLocation
                    searchState.endAddress = ""
                    appState.selectedEndLocation = nil
                } else if !searchState.startAddress.isEmpty {
                    appState.selectedEndLocation = nil
                    searchState.endAddress = ""
                    searchState.suppressEndSearch = true
                    searchState.isSearchingEnd = false
                } else {
                    appState.selectedStartLocation = nil
                    searchState.startAddress = ""
                    searchState.suppressStartSearch = true
                    searchState.isSearchingStart = false
                }

                // Transfer end address to start address since we're keeping the end point as single location

                // If we had a route, clear it since we changed points
                appState.route = nil

                // Center map on the remaining point
                if let endLocation = appState.selectedEndLocation {
                    centerMapOnCoordinate(endLocation)
                }
            }
        }

        clearSearchResults()
    }


    func clearSelections() {
        appState.selectedStartLocation = nil
        appState.selectedEndLocation = nil
        appState.route = nil
        appState.isTwoFieldMode = false  // Reset to default single field mode

        searchState.startAddress = ""
        searchState.endAddress = ""

        clearSearchResults()
    }

    func clearMap() {
        clearSelections()
    }

    func fitToRoute() {
        guard let route = appState.route else { return }

        let rect = route.polyline.boundingMapRect
        appState.region = MKCoordinateRegion(rect)
    }

    func pickPoint() {
        appState.selectedEndLocation = nil
        appState.route = nil
        appState.isTwoFieldMode = false
        clearSelections()
    }

    // MARK: - Location Search

    func searchForLocation(query: String, isStart: Bool) {
        guard !query.isEmpty else {
            clearSearchResults(for: isStart ? .start : .end)
            return
        }

        // Cancel previous search
        cancelSearch(for: isStart ? .start : .end)

        // Start new debounced search
        let task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(searchDebounceDelay * 1_000_000_000))

                if Task.isCancelled { return }

                await performLocationSearch(query: query, isStart: isStart)
            } catch {
                // Task cancelled, ignore
            }
        }

        searchTasks[isStart ? "start" : "end"] = task
    }

    func searchForSingleLocation(query: String) {
        guard !query.isEmpty else {
            clearSearchResults(for: .start) // Use start instead of single
            return
        }

        cancelSearch(for: .start) // Use start instead of single

        let task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(searchDebounceDelay * 1_000_000_000))

                if Task.isCancelled { return }

                await performLocationSearch(query: query, isStart: true)
            } catch {
                // Task cancelled, ignore
            }
        }

        searchTasks["start"] = task // Use start instead of single
    }

    func selectLocation(_ item: MKMapItem, isStart: Bool) {
        let coordinate = item.placemark.coordinate

        if isStart {
            appState.selectedStartLocation = coordinate
            searchState.startAddress = item.name ?? (item.placemark.title ?? "")
            searchState.startSearchResults = []
            searchState.isSearchingStart = false
        } else {
            appState.selectedEndLocation = coordinate
            searchState.endAddress = item.name ?? (item.placemark.title ?? "")
            searchState.endSearchResults = []
            searchState.isSearchingEnd = false
        }

        // Update map region
        appState.region.center = coordinate

        // Update mode based on selections
        updateModeAfterSelection()
    }

    func selectSingleLocation(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        appState.selectedStartLocation = coordinate
        searchState.startAddress = item.name ?? (item.placemark.title ?? "") // Use startAddress
        searchState.startSearchResults = [] // Use startSearchResults
        searchState.isSearchingStart = false // Use isSearchingStart

        appState.region.center = coordinate
        appState.isTwoFieldMode = false
    }

    // MARK: - Route Calculation

    func calculateRoute() async {
        guard canCalculateRoute() && validateInputsForAction(),
              let start = appState.selectedStartLocation,
              let end = appState.selectedEndLocation else {
            return
        }

        exportState.isCalculatingRoute = true
        defer { exportState.isCalculatingRoute = false }

        do {
            let route = try await performRouteCalculation(from: start, to: end)
            appState.route = route

            if appState.selectedStartLocation != nil && appState.selectedEndLocation != nil {
                appState.isTwoFieldMode = true
            }
        } catch {
            let errorMessage: String
            let nsError = error as NSError
            if nsError.domain == "MKErrorDomain" {
                errorMessage = "Route calculation failed. Check your internet connection and try different locations."
            } else {
                errorMessage = error.localizedDescription
            }
            showError(.routeCalculationFailed(errorMessage))
        }
    }

    // MARK: - GPX Export

    func prepareRouteGPX() -> (content: String, filename: String)? {
        guard canExportRoute() && validateInputsForAction(), let route = appState.route else {
            return nil
        }

        do {
            let gpxString = try generateRouteGPX(route: route)
            let filename = createRouteFilename()
            return (gpxString, filename)
        } catch {
            showError(.fileSaveFailed(error.localizedDescription))
            return nil
        }
    }

    func prepareWaypointGPX() -> (content: String, filename: String)? {
        guard canExportWaypoint() && validateInputsForAction() else {
            return nil
        }

        let coordinate = appState.selectedEndLocation ?? appState.selectedStartLocation
        guard let point = coordinate else {
            return nil
        }

        let address = getAddressForCoordinate(point)
        let gpxString = generateWaypointGPX(coordinate: point, name: address)
        let filename = createWaypointFilename(for: address)
        return (gpxString, filename)
    }

    // MARK: - Map Interaction

    func handleMapClick(at coordinate: CLLocationCoordinate2D) {
        // Validate coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            showError(.invalidCoordinates("Invalid location selected"))
            return
        }

        // Determine which location we're setting and update coordinates
        var targetField: String = "start" // Default to start field

        if appState.selectedStartLocation == nil {
            // Setting the first/start location
            appState.selectedStartLocation = coordinate
            targetField = "start"
            // Center map on the selected point
            centerMapOnCoordinate(coordinate)
        } else if appState.selectedEndLocation == nil {
            // Setting the second/end location
            appState.selectedEndLocation = coordinate
            targetField = "end"

            // Center map between both points
            centerMapBetweenPoints()
            // Automatically switch to two-field mode when both points are selected
            appState.isTwoFieldMode = true
        } else {
            // Both points already selected, replace the most recently added point (end point)
            appState.selectedEndLocation = coordinate
            targetField = "end"
            // Clear any existing route since we're changing the end location
            appState.route = nil
            centerMapBetweenPoints()
        }

        // Set immediate coordinate display for the appropriate field
        let coordinateString = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
        if targetField == "start" {
            searchState.startAddress = coordinateString
            searchState.suppressStartSearch = true
            searchState.isSearchingStart = false
        } else {
            searchState.endAddress = coordinateString
            searchState.suppressEndSearch = true
            searchState.isSearchingEnd = false
        }

        // Perform reverse geocoding to get address
        Task {
            do {
                let address = try await reverseGeocodeLocation(coordinate)

                await MainActor.run {
                    // Update the appropriate field with the geocoded address
                    if targetField == "start" {
                        searchState.startAddress = address
                        searchState.suppressStartSearch = true
                    } else {
                        searchState.endAddress = address
                        searchState.suppressEndSearch = true
                    }
                }
            } catch {
                // Reverse geocoding failed, but we already set the coordinate string, so no need to update
                // The field already shows the coordinate string, so we don't need to change it
            }
        }
    }

    // MARK: - Private Methods

    private func performLocationSearch(query: String, isStart: Bool = true) async {
        let searchType: SearchType = isStart ? .start : .end

        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            // Global search - no region restriction

            let search = MKLocalSearch(request: request)

            let response = try await search.start()

            await MainActor.run {
                let results = Array(response.mapItems.prefix(5))

                if isStart {
                    searchState.startSearchResults = results
                    searchState.isSearchingStart = true
                } else {
                    searchState.endSearchResults = results
                    searchState.isSearchingEnd = true
                }

                if results.count >= 5 {
                    showWarning(.searchResultsLimited)
                }
            }
        } catch {
            await MainActor.run {
                let nsError = error as NSError
                let errorMessage = nsError.domain == "MKErrorDomain" ?
                    "Location search failed. Check your internet connection and try again." :
                    error.localizedDescription
                showError(.locationSearchFailed(errorMessage))
                clearSearchResults(for: searchType)
            }
        }
    }


    private func performRouteCalculation(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> MKRoute {
        let startPlacemark = MKPlacemark(coordinate: start)
        let endPlacemark = MKPlacemark(coordinate: end)

        let startItem = MKMapItem(placemark: startPlacemark)
        let endItem = MKMapItem(placemark: endPlacemark)

        let request = MKDirections.Request()
        request.source = startItem
        request.destination = endItem
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        let response = try await directions.calculate()

        guard let route = response.routes.first else {
            throw GPXError.routeCalculationFailed("No route found")
        }

        return route
    }

    private func reverseGeocodeLocation(_ coordinate: CLLocationCoordinate2D) async throws -> String {
        let key = CoordinateKey(coordinate)
        // Check cache first
        if let cachedAddress = geocodeCache[key] {
            return cachedAddress
        }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        let placemarks = try await geocoder.reverseGeocodeLocation(location)

        guard let placemark = placemarks.first else {
            throw GPXError.reverseGeocodingFailed("No address found")
        }

        let parts: [String] = [placemark.name, placemark.locality, placemark.administrativeArea].compactMap { $0 }
        let address = parts.first ?? "Selected Location"

        // Cache the result
        cacheGeocodeResult(coordinate, address: address)

        return address
    }

    private func cacheGeocodeResult(_ coordinate: CLLocationCoordinate2D, address: String) {
        let key = CoordinateKey(coordinate)
        // If cache is full, remove oldest entry
        if geocodeCache.count >= geocodeCacheLimit {
            let firstKey = geocodeCache.keys.first!
            geocodeCache.removeValue(forKey: firstKey)
        }
        geocodeCache[key] = address
    }

    private func generateRouteGPX(route: MKRoute) throws -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        var currentTime = Date()

        let coordinates = sampledCoordinates(from: route.polyline, maxPoints: 200)

        let startAddress = searchState.startAddress.isEmpty ? "Start" : searchState.startAddress
        let endAddress = searchState.endAddress.isEmpty ? "End" : searchState.endAddress

        // Use array for efficient string building with large datasets
        var gpxLines: [String] = []
        gpxLines.reserveCapacity(coordinates.count + 10) // Pre-allocate capacity

        gpxLines.append("<?xml version=\"1.0\"?>")
        gpxLines.append("<gpx version=\"1.1\" creator=\"GPX Creator • Bandan Kumar Mahto\">")
        gpxLines.append("    <metadata>")
        gpxLines.append("        <name>Route from \(startAddress) to \(endAddress)</name>")
        gpxLines.append("        <time>\(formatter.string(from: currentTime))</time>")
        gpxLines.append("    </metadata>")

        var previous: CLLocationCoordinate2D?
        for coord in coordinates {
            if let prev = previous {
                let dist = distanceMeters(from: prev, to: coord)
                let speedMps = appState.simulationSpeed / 3.6
                let seconds = max(1, Int(dist / speedMps))
                currentTime.addTimeInterval(TimeInterval(seconds))
            }
            previous = coord

            gpxLines.append("    <wpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\">")
            gpxLines.append("        <time>\(formatter.string(from: currentTime))</time>")
            gpxLines.append("    </wpt>")
        }

        gpxLines.append("</gpx>")

        // Join with newlines for efficient string creation
        return gpxLines.joined(separator: "\n")
    }

    private func generateWaypointGPX(coordinate: CLLocationCoordinate2D, name: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: Date())

        return """
            <?xml version="1.0"?>
            <gpx version="1.1" creator="GPX Creator • Bandan Kumar Mahto">
                <wpt lat="\(coordinate.latitude)" lon="\(coordinate.longitude)">
                    <name>\(name)</name>
                    <time>\(timestamp)</time>
                </wpt>
            </gpx>
            """
    }

    private func sampledCoordinates(from polyline: MKPolyline, maxPoints: Int) -> [CLLocationCoordinate2D] {
        let count = polyline.pointCount
        guard count > 0 else { return [] }

        let points = polyline.points()

        // For small routes, return all points
        if count <= maxPoints {
            var coords: [CLLocationCoordinate2D] = []
            coords.reserveCapacity(count)
            for i in 0..<count {
                coords.append(points[i].coordinate)
            }
            return coords
        }

        // For large routes, use distance-based sampling to maintain route accuracy
        var coords: [CLLocationCoordinate2D] = []
        coords.reserveCapacity(maxPoints)

        // Always include the first point
        coords.append(points[0].coordinate)

        let totalDistance = calculatePolylineDistance(polyline)
        let targetSegmentDistance = totalDistance / Double(maxPoints - 1) // -1 to account for start and end

        var currentDistance: Double = 0

        for i in 1..<count {
            let segmentDistance = distanceMeters(from: points[i-1].coordinate, to: points[i].coordinate)
            currentDistance += segmentDistance

            // Include point if we've traveled far enough or if it's the last point
            if currentDistance >= targetSegmentDistance || i == count - 1 {
                // Avoid duplicates
                let currentCoord = points[i].coordinate
                if coords.last?.latitude != currentCoord.latitude ||
                   coords.last?.longitude != currentCoord.longitude {
                    coords.append(currentCoord)
                }
                currentDistance = 0

                // Break if we've reached our target count (but always include the last point)
                if coords.count >= maxPoints - 1 && i < count - 1 {
                    break
                }
            }
        }

        // Always ensure the last point is included
        let lastCoord = points[count - 1].coordinate
        if coords.last?.latitude != lastCoord.latitude ||
           coords.last?.longitude != lastCoord.longitude {
            coords.append(lastCoord)
        }

        return coords
    }

    private func calculatePolylineDistance(_ polyline: MKPolyline) -> Double {
        let points = polyline.points()
        let count = polyline.pointCount
        var totalDistance: Double = 0

        for i in 1..<count {
            totalDistance += distanceMeters(from: points[i-1].coordinate, to: points[i].coordinate)
        }

        return totalDistance
    }

    private func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }

    private func updateModeAfterSelection() {
        if appState.selectedStartLocation != nil && appState.selectedEndLocation != nil {
            appState.isTwoFieldMode = true
        } else if appState.selectedStartLocation != nil && appState.selectedEndLocation == nil {
            appState.isTwoFieldMode = false
        }
    }

    private func centerMapOnCoordinate(_ coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )
        appState.region = region
    }

    private func centerMapBetweenPoints() {
        guard let start = appState.selectedStartLocation,
              let end = appState.selectedEndLocation else { return }

        // Calculate center point between start and end
        let centerLat = (start.latitude + end.latitude) / 2
        let centerLon = (start.longitude + end.longitude) / 2
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)

        // Calculate span to fit both points with some padding
        let latDelta = abs(start.latitude - end.latitude) * 1.5
        let lonDelta = abs(start.longitude - end.longitude) * 1.5

        // Ensure minimum span for visibility
        let minSpan: CLLocationDegrees = 0.05
        let span = MKCoordinateSpan(
            latitudeDelta: max(latDelta, minSpan),
            longitudeDelta: max(lonDelta, minSpan)
        )

        let region = MKCoordinateRegion(center: center, span: span)
        appState.region = region
    }

    private func clearSearchResults(for type: SearchType? = nil) {
        if type == nil || type == .start {
            searchState.startSearchResults = []
            searchState.isSearchingStart = false
        }
        if type == nil || type == .end {
            searchState.endSearchResults = []
            searchState.isSearchingEnd = false
        }
    }

    private func cancelSearch(for type: SearchType) {
        let key = type.rawValue
        searchTasks[key]?.cancel()
        searchTasks[key] = nil
    }

    private func createRouteFilename() -> String {
        let start = searchState.startAddress.components(separatedBy: ",").first ?? searchState.startAddress
        let end = searchState.endAddress.components(separatedBy: ",").first ?? searchState.endAddress
        return "\(start)_to_\(end)".replacingOccurrences(of: " ", with: "_")
    }

    private func createWaypointFilename(for address: String) -> String {
        return (address.components(separatedBy: ",").first ?? address).replacingOccurrences(of: " ", with: "_")
    }

    private func getAddressForCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        if !searchState.endAddress.isEmpty {
            return searchState.endAddress
        } else if !searchState.startAddress.isEmpty {
            return searchState.startAddress
        } else {
            return "Waypoint"
        }
    }

    private func validateInputsForAction() -> Bool {
        // Validate simulation speed
        guard appState.simulationSpeed >= minSimulationSpeed && appState.simulationSpeed <= maxSimulationSpeed else {
            showError(.invalidCoordinates("Simulation speed must be between \(Int(minSimulationSpeed)) and \(Int(maxSimulationSpeed)) km/h"))
            return false
        }

        // Validate that addresses are not empty if in two-field mode
        if appState.isTwoFieldMode {
            if searchState.startAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showWarning(.noLocationSelected)
                return false
            }
            if searchState.endAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showWarning(.noLocationSelected)
                return false
            }
        } else {
            if searchState.startAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showWarning(.noLocationSelected)
                return false
            }
        }

        return true
    }

    func canCalculateRoute() -> Bool {
        return appState.selectedStartLocation != nil &&
               appState.selectedEndLocation != nil &&
               !exportState.isCalculatingRoute
    }

    func canExportRoute() -> Bool {
        return appState.route != nil
    }

    func canExportWaypoint() -> Bool {
        return (appState.selectedStartLocation != nil || appState.selectedEndLocation != nil)
    }

    private func showError(_ error: GPXError) {
        errorState.currentError = error
        errorState.showError = true
    }

    private func showWarning(_ warning: GPXWarning) {
        errorState.currentWarning = warning.rawValue
        errorState.showWarning = true
    }
}

// MARK: - CLLocationManagerDelegate

extension GPXCreatorViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Validate coordinate
        guard CLLocationCoordinate2DIsValid(location.coordinate) else { return }

        // Only update region if no points have been selected yet (initial setup)
        // Once user starts selecting points, don't override with current location
        guard appState.selectedStartLocation == nil && appState.selectedEndLocation == nil else {
            return
        }

        let coordinate = location.coordinate
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )

        DispatchQueue.main.async {
            self.appState.region = region
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location request failed, keep the fallback location
        print("Location request failed: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorized || status == .authorizedAlways {
            manager.requestLocation()
        }
    }
}

// MARK: - Supporting Types

enum SearchType: String {
    case start, end
}

struct AppState {
    var region = MKCoordinateRegion()
    var selectedStartLocation: CLLocationCoordinate2D?
    var selectedEndLocation: CLLocationCoordinate2D?
    var isTwoFieldMode = false
    var route: MKRoute?
    var simulationSpeed: Double = 20
}

struct SearchState {
    var startAddress = ""
    var endAddress = ""
    var startSearchResults: [MKMapItem] = []
    var endSearchResults: [MKMapItem] = []
    var isSearchingStart = false
    var isSearchingEnd = false
    var suppressStartSearch = false
    var suppressEndSearch = false
}

struct ExportState {
    var isCalculatingRoute = false
    var isExporting = false
}

struct ErrorState {
    var showError = false
    var showWarning = false
    var currentError: GPXError?
    var currentWarning = ""
}

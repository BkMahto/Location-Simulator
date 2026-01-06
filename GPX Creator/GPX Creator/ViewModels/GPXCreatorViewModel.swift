//
//  GPXCreatorViewModel.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import Combine
import CoreLocation
import LocationHelperCore
import MapKit
import SwiftUI

/// The Main Actor isolated ViewModel for managing GPX creation and simulation logic.
///
/// This class handles map interaction, location search, route calculation, and GPX file generation.
@MainActor
class GPXCreatorViewModel: NSObject, ObservableObject {
    // MARK: - Published State

    /// The core application state including current map region and mode.
    @Published var appState = AppState()

    /// State related to location searching and search results.
    @Published var searchState = SearchState()

    /// State related to route calculation and GPX export processes.
    @Published var exportState = ExportState()

    /// State for handling and displaying errors or warnings to the user.
    @Published var errorState = ErrorState()

    // MARK: - Private Properties
    private var searchTasks = [String: Task<Void, Never>]()
    private let geocoder = CLGeocoder()
    private let locationSearch = MKLocalSearch.self
    private var geocodeCache = [CoordinateKey: String]()
    private let geocodeCacheLimit = 50
    private let locationHelper = BaseLocationHelper()

    private var cancellables = Set<AnyCancellable>()

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

    /// Configures the initial state of the application, including a fallback map region and requesting user location.
    private func setupInitialState() {
        // Start with fallback location
        let fallbackCoordinate = CLLocationCoordinate2D(latitude: 22.47769553, longitude: 70.0467413)
        appState.region = MKCoordinateRegion(
            center: fallbackCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        )

        // Request user's current location via shared helper
        locationHelper.requestAuthorization()

        // Observe location updates
        locationHelper.$currentLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] coordinate in
                self?.handleLocationUpdate(coordinate)
            }
            .store(in: &cancellables)
    }

    private func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        guard appState.selectedStartLocation == nil && appState.selectedEndLocation == nil else {
            return
        }
        centerMapOnCoordinate(coordinate)
    }

    // MARK: - Public Methods

    /// Updates the simulation speed for GPX generation, ensuring it stays within valid bounds.
    /// - Parameter newSpeed: The desired speed in km/h.
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

    /// Toggles between single-location mode and two-field (start/end) mode.
    ///
    /// When switching to two-field mode, existing selections are maintained where possible.
    /// When switching back to single-location mode, the map state is consolidated to a single point.
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
                if !searchState.startAddress.isEmpty {
                    if let startLocation = appState.selectedStartLocation {
                        centerMapOnCoordinate(startLocation)
                    }
                } else {
                    if let endLocation = appState.selectedEndLocation {
                        centerMapOnCoordinate(endLocation)
                    }
                }
            }
        }

        clearSearchResults()
    }

    /// Resets all selections and search states back to their default values.
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

    /// Adjusts the map view to fit the entire calculated route.
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

    /// Initiates a debounced search for a location based on a string query.
    /// - Parameters:
    ///   - query: The address or place name to search for.
    ///   - isStart: Boolean indicating if this is for the start field (true) or end field (false).
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
            clearSearchResults(for: .start)  // Use start instead of single
            return
        }

        cancelSearch(for: .start)  // Use start instead of single

        let task = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(searchDebounceDelay * 1_000_000_000))

                if Task.isCancelled { return }

                await performLocationSearch(query: query, isStart: true)
            } catch {
                // Task cancelled, ignore
            }
        }

        searchTasks["start"] = task  // Use start instead of single
    }

    /// Completes the location selection process for a given map item.
    /// - Parameters:
    ///   - item: The `MKMapItem` selected from search results.
    ///   - isStart: Boolean indicating if this selection is for the start or end position.
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
        searchState.startAddress = item.name ?? (item.placemark.title ?? "")  // Use startAddress
        searchState.startSearchResults = []  // Use startSearchResults
        searchState.isSearchingStart = false  // Use isSearchingStart

        appState.region.center = coordinate
        appState.isTwoFieldMode = false
    }

    // MARK: - Route Calculation

    /// Calculates the driving route between the selected start and end locations.
    ///
    /// This method is asynchronous and updates the `appState.route` upon successful completion.
    func calculateRoute() async {
        guard canCalculateRoute() && validateInputsForAction(),
            let start = appState.selectedStartLocation,
            let end = appState.selectedEndLocation
        else { return }

        exportState.isCalculatingRoute = true
        defer { exportState.isCalculatingRoute = false }

        do {
            let route = try await performRouteCalculation(from: start, to: end)
            appState.route = route

            if appState.selectedStartLocation != nil && appState.selectedEndLocation != nil {
                appState.isTwoFieldMode = true
            }
            fitToRoute()
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

    /// Preparates the GPX content for the current calculated route.
    /// - Returns: A tuple containing the GPX string content and a suggested filename, or nil if export is not possible.
    func prepareRouteGPX() -> (content: String, filename: String)? {
        guard canExportRoute() && validateInputsForAction(), let route = appState.route else {
            return nil
        }

        let gpxString = GPXHelper.generateRouteGPX(
            route: route,
            simulationSpeed: appState.simulationSpeed,
            startAddress: searchState.startAddress,
            endAddress: searchState.endAddress
        )
        let filename = GPXHelper.createRouteFilename(start: searchState.startAddress, end: searchState.endAddress)
        return (gpxString, filename)
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
        let gpxString = GPXHelper.generateWaypointGPX(coordinate: point, name: address)
        let filename = GPXHelper.createWaypointFilename(for: address)
        return (gpxString, filename)
    }

    // MARK: - Map Interaction

    /// Handles a user click on the map by setting markers and initiating reverse geocoding.
    ///
    /// If no start location is selected, the click sets the start location.
    /// If a start location exists but no end location, it sets the end location and switches to two-field mode.
    /// If both exist, it replaces the end location.
    /// - Parameter coordinate: The geographic coordinate where the user clicked.
    func handleMapClick(at coordinate: CLLocationCoordinate2D) {
        // Validate coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            showError(.invalidCoordinates("Invalid location selected"))
            return
        }

        // Determine which location we're setting and update coordinates
        var targetField: String = "start"  // Default to start field

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

    /// Internal method to perform the actual location search using MKLocalSearch.
    /// - Parameters:
    ///   - query: The string to search for.
    ///   - isStart: Whether this is for the start or end location.
    private func performLocationSearch(query: String, isStart: Bool = true) async {
        let searchType: SearchType = isStart ? .start : .end

        do {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query

            // Bias search results based on start location if available
            if let startLocation = appState.selectedStartLocation {
                // If start location is set, bias search towards that region (country-level)
                let searchRegion = MKCoordinateRegion(
                    center: startLocation,
                    span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)  // ~1000km radius
                )
                request.region = searchRegion
            } else {
                // No start location set, use current map region for global search
                request.region = appState.region
            }

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
                let errorMessage =
                    nsError.domain == "MKErrorDomain"
                    ? "Location search failed. Check your internet connection and try again." : error.localizedDescription
                showError(.locationSearchFailed(errorMessage))
                clearSearchResults(for: searchType)
            }
        }
    }

    /// Internal method to calculate a route between two coordinates.
    /// - Parameters:
    ///   - start: The starting coordinate.
    ///   - end: The destination coordinate.
    /// - Returns: An `MKRoute` object on success.
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

    private func calculatePolylineDistance(_ polyline: MKPolyline) -> Double {
        return CoordinateUtils.calculatePolylineDistance(polyline)
    }

    private func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        return CoordinateUtils.distanceMeters(from: a, to: b)
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
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        appState.region = region
    }

    private func centerMapBetweenPoints() {
        guard let start = appState.selectedStartLocation,
            let end = appState.selectedEndLocation
        else { return }

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
        return appState.selectedStartLocation != nil && appState.selectedEndLocation != nil && !exportState.isCalculatingRoute
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

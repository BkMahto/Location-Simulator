//
//  ContentView.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import AppKit
import CoreLocation
import MapKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.47769553, longitude: 70.0467413),  // Jamnagar, Gujarat
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )

    @State private var selectedStartLocation: CLLocationCoordinate2D?
    @State private var selectedEndLocation: CLLocationCoordinate2D?
    @State private var isPathMode = true
    @State private var isTwoFieldMode = false
    @State private var route: MKRoute?
    @State private var isCalculatingRoute = false

    // Address input fields
    @State private var startAddress = ""
    @State private var endAddress = ""
    @State private var singleAddress = ""

    @State private var simulationSpeed: Double = 20

    // Location search
    @State private var startSearchResults: [MKMapItem] = []
    @State private var endSearchResults: [MKMapItem] = []
    @State private var singleSearchResults: [MKMapItem] = []

    @State private var isSearchingStart = false
    @State private var isSearchingEnd = false
    @State private var isSearchingSingle = false
    @State private var suppressStartSearch = false
    @State private var suppressEndSearch = false
    @State private var suppressSingleSearch = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with toggle
            HStack {
                Text("GPX Creator")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                HStack {
                    Text("Simulation Speed")
                        .font(.headline)

                    TextField("Enter Simulation Speed", value: $simulationSpeed, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 80)
                        .onSubmit {
                            validateSimulationSpeed()
                        }
                    Text("km/h")
                        .font(.subheadline)
                }

                Toggle("Two Fields", isOn: $isTwoFieldMode)
                    .toggleStyle(SwitchToggleStyle())
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            // Address input section
            VStack(spacing: 12) {
                if isTwoFieldMode {
                    // Two field mode
                    VStack(spacing: 8) {
                        HStack {
                            Text("Start Location")
                                .font(.headline)
                            Spacer()
                        }

                        TextField("Enter start address", text: $startAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: startAddress) {
                                if suppressStartSearch {
                                    suppressStartSearch = false
                                    isSearchingStart = false
                                } else {
                                    searchForLocation(query: startAddress, isStart: true)
                                }
                            }

                        if isSearchingStart && !startSearchResults.isEmpty {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(startSearchResults.prefix(3), id: \.self) { item in
                                        Button(action: {
                                            selectLocation(item, isStart: true)
                                        }) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name ?? "Unknown")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                Text(item.placemark.title ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .cornerRadius(8)
                        }
                    }

                    VStack(spacing: 8) {
                        HStack {
                            Text("End Location")
                                .font(.headline)
                            Spacer()
                        }

                        TextField("Enter end address", text: $endAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: endAddress) {
                                if suppressEndSearch {
                                    suppressEndSearch = false
                                    isSearchingEnd = false
                                } else {
                                    searchForLocation(query: endAddress, isStart: false)
                                }
                            }

                        if isSearchingEnd && !endSearchResults.isEmpty {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(endSearchResults.prefix(3), id: \.self) { item in
                                        Button(action: {
                                            selectLocation(item, isStart: false)
                                        }) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name ?? "Unknown")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                Text(item.placemark.title ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                } else {
                    // Single field mode
                    VStack(spacing: 8) {
                        HStack {
                            Text("Location")
                                .font(.headline)
                            Spacer()
                        }

                        TextField("Enter address", text: $singleAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: singleAddress) {
                                if suppressSingleSearch {
                                    suppressSingleSearch = false
                                    isSearchingSingle = false
                                } else {
                                    searchForSingleLocation(query: singleAddress)
                                }
                            }

                        if isSearchingSingle && !singleSearchResults.isEmpty {
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(singleSearchResults.prefix(3), id: \.self) { item in
                                        Button(action: {
                                            selectSingleLocation(item)
                                        }) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(item.name ?? "Unknown")
                                                    .font(.body)
                                                    .foregroundColor(.primary)
                                                Text(item.placemark.title ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 4)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .frame(maxHeight: 120)
                            .background(Color(nsColor: .windowBackgroundColor))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            // Map view
            MapView(
                region: $region,
                selectedStartLocation: $selectedStartLocation,
                selectedEndLocation: $selectedEndLocation,
                isPathMode: $isPathMode,
                route: $route,
                isCalculatingRoute: $isCalculatingRoute,
                startAddress: $startAddress,
                endAddress: $endAddress,
                singleAddress: $singleAddress,
                isTwoFieldMode: $isTwoFieldMode,
                suppressStartSearch: $suppressStartSearch,
                suppressEndSearch: $suppressEndSearch,
                suppressSingleSearch: $suppressSingleSearch,
                isSearchingStart: $isSearchingStart,
                isSearchingEnd: $isSearchingEnd,
                isSearchingSingle: $isSearchingSingle
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Control buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: {
                        isPathMode.toggle()
                    }) {
                        HStack {
                            Image(systemName: isPathMode ? "line.diagonal" : "plus.circle")
                            Text(isPathMode ? "Exit Path Mode" : "Create Path")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isPathMode ? .red : .blue)

                    Button(action: {
                        if let r = route {
                            let rect = r.polyline.boundingMapRect
                            let fitted = MKCoordinateRegion(rect)
                            region = fitted
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.and.arrow.up.right.and.arrow.down.left")
                            Text("Fit to Route")
                        }
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        // Enable a single click to pick a point
                        selectedEndLocation = nil
                        route = nil
                        isTwoFieldMode = false
                        isPathMode = true
                    }) {
                        HStack {
                            Image(systemName: "mappin")
                            Text("Pick Point")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    Button(action: {
                        calculateRoute()
                        if selectedStartLocation != nil && selectedEndLocation != nil {
                            isTwoFieldMode = true
                        }
                    }) {
                        HStack {
                            if isCalculatingRoute {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "road.lanes")
                            }
                            Text("Calculate Route")
                        }
                    }
                    .disabled(selectedStartLocation == nil || selectedEndLocation == nil || isCalculatingRoute)
                    .buttonStyle(.borderedProminent)
                    .tint((selectedStartLocation != nil && selectedEndLocation != nil) ? .orange : .gray)

                    Button(action: {
                        clearSelections()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 12) {
                    Button(action: {
                        exportWaypointGPX()
                    }) {
                        HStack {
                            Image(systemName: "smallcircle.filled.circle")
                            Text("Export Point GPX")
                        }
                    }
                    .disabled(selectedStartLocation == nil && selectedEndLocation == nil)
                    .buttonStyle(.borderedProminent)
                    .tint((selectedStartLocation != nil || selectedEndLocation != nil) ? .green : .gray)

                    Button(action: {
                        exportGPX()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export GPX")
                        }
                    }
                    .disabled(route == nil)
                    .buttonStyle(.borderedProminent)
                    .tint(route != nil ? .green : .gray)

                    Button(action: {
                        clearMap()
                    }) {
                        HStack {
                            Image(systemName: "map")
                            Text("Clear Map")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(.purple)
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

#Preview {
    ContentView()
}

extension ContentView {

    private func validateSimulationSpeed() {
        var adjusted = max(20, simulationSpeed)
        adjusted = (adjusted / 10) * 10
        simulationSpeed = adjusted
    }

    private func searchForLocation(query: String, isStart: Bool) {
        guard !query.isEmpty else {
            if isStart {
                startSearchResults = []
                isSearchingStart = false
            } else {
                endSearchResults = []
                isSearchingEnd = false
            }
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response {
                    if isStart {
                        startSearchResults = response.mapItems
                        isSearchingStart = true
                    } else {
                        endSearchResults = response.mapItems
                        isSearchingEnd = true
                    }
                }
            }
        }
    }

    private func searchForSingleLocation(query: String) {
        guard !query.isEmpty else {
            singleSearchResults = []
            isSearchingSingle = false
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                if let response = response {
                    singleSearchResults = response.mapItems
                    isSearchingSingle = true
                }
            }
        }
    }

    private func selectLocation(_ item: MKMapItem, isStart: Bool) {
        let coordinate = item.placemark.coordinate

        if isStart {
            selectedStartLocation = coordinate
            startAddress = item.name ?? (item.placemark.title ?? "")
            startSearchResults = []
            isSearchingStart = false
        } else {
            selectedEndLocation = coordinate
            endAddress = item.name ?? (item.placemark.title ?? "")
            endSearchResults = []
            isSearchingEnd = false
        }

        // Update map region to show the selected location
        region.center = coordinate

        // Switch to two-field mode when both selected
        if selectedStartLocation != nil && selectedEndLocation != nil {
            isTwoFieldMode = true
        } else if selectedStartLocation != nil && selectedEndLocation == nil {
            isTwoFieldMode = false
        }
    }

    private func selectSingleLocation(_ item: MKMapItem) {
        let coordinate = item.placemark.coordinate
        selectedStartLocation = coordinate
        singleAddress = item.name ?? (item.placemark.title ?? "")
        singleSearchResults = []
        isSearchingSingle = false

        // Update map region to show the selected location
        region.center = coordinate

        // Single point selection should switch to single-field mode
        isTwoFieldMode = false
    }

    private func calculateRoute() {
        guard let start = selectedStartLocation, let end = selectedEndLocation else { return }

        isCalculatingRoute = true
        // Ensure addresses are present for UI/filenames
        fillAddressesIfMissing(start: start, end: end)

        let startPlacemark = MKPlacemark(coordinate: start)
        let endPlacemark = MKPlacemark(coordinate: end)

        let startItem = MKMapItem(placemark: startPlacemark)
        let endItem = MKMapItem(placemark: endPlacemark)

        let request = MKDirections.Request()
        request.source = startItem
        request.destination = endItem
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                isCalculatingRoute = false

                if let route = response?.routes.first {
                    self.route = route
                    // Do not auto-recenter; let user choose via "Fit to Route"
                    // Keep two-field mode when a route exists
                    if self.selectedStartLocation != nil && self.selectedEndLocation != nil {
                        self.isTwoFieldMode = true
                    }
                } else if let error = error {
                    print("Route calculation error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fillAddressesIfMissing(start: CLLocationCoordinate2D, end: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        if startAddress.isEmpty {
            geocoder.reverseGeocodeLocation(CLLocation(latitude: start.latitude, longitude: start.longitude)) { placemarks, _ in
                if let p = placemarks?.first {
                    let parts: [String] = [p.name, p.locality, p.administrativeArea].compactMap { $0 }
                    let title = parts.first ?? "Start"
                    DispatchQueue.main.async {
                        self.startAddress = title
                        self.suppressStartSearch = true
                        self.isSearchingStart = false
                    }
                }
            }
        }
        if endAddress.isEmpty {
            geocoder.reverseGeocodeLocation(CLLocation(latitude: end.latitude, longitude: end.longitude)) { placemarks, _ in
                if let p = placemarks?.first {
                    let parts: [String] = [p.name, p.locality, p.administrativeArea].compactMap { $0 }
                    let title = parts.first ?? "End"
                    DispatchQueue.main.async {
                        self.endAddress = title
                        self.suppressEndSearch = true
                        self.isSearchingEnd = false
                    }
                }
            }
        }
    }

    private func clearSelections() {
        selectedStartLocation = nil
        selectedEndLocation = nil
        startAddress = ""
        endAddress = ""
        singleAddress = ""
        startSearchResults = []
        endSearchResults = []
        singleSearchResults = []
        isSearchingStart = false
        isSearchingEnd = false
        isSearchingSingle = false
        isPathMode = false
        route = nil
    }

    private func clearMap() {
        selectedStartLocation = nil
        selectedEndLocation = nil
        route = nil
        startAddress = ""
        endAddress = ""
        singleAddress = ""
        startSearchResults = []
        endSearchResults = []
        singleSearchResults = []
        isSearchingStart = false
        isSearchingEnd = false
        isSearchingSingle = false
        isPathMode = false
    }

    private func exportGPX() {
        guard let route = route else { return }

        // Use waypoint-based GPX with increasing timestamps for best Xcode simulation
        let gpxString = generateWaypointRouteGPX(route: route, assumedSpeed: simulationSpeed)
        let baseName: String
        if !startAddress.isEmpty && !endAddress.isEmpty {
            let s = startAddress.components(separatedBy: ",").first ?? startAddress
            let e = endAddress.components(separatedBy: ",").first ?? endAddress
            baseName = "\(s)_to_\(e)".replacingOccurrences(of: " ", with: "_")
        } else {
            baseName = "route"
        }

        // Create a save panel for macOS
        DispatchQueue.main.async {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType(filenameExtension: "gpx") ?? .xml]
            savePanel.nameFieldStringValue = "\(baseName).gpx"
            savePanel.title = "Save GPX File"

            savePanel.begin { result in
                if result == .OK, let url = savePanel.url {
                    do {
                        try gpxString.write(to: url, atomically: true, encoding: .utf8)
                        print("GPX file saved to: \(url.path)")
                    } catch {
                        print("Error saving GPX file: \(error)")
                    }
                }
            }
        }
    }

    private func generateWaypointRouteGPX(route: MKRoute, assumedSpeed: Double = 20.0) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        var currentTime = Date()

        let coordinates = sampledCoordinates(from: route.polyline, maxPoints: 200)

        var gpx = """
            <?xml version="1.0"?>
            <gpx version="1.1" creator="GPX Creator • Bandan Kumar Mahto" xmlns="http://www.topografix.com/GPX/1/1">
                <metadata>
                    <name>Route from \(startAddress) to \(endAddress)</name>
                    <time>\(formatter.string(from: currentTime))</time>
                </metadata>
            """

        var previous: CLLocationCoordinate2D?
        for coord in coordinates {
            if let prev = previous {
                let dist = distanceMeters(from: prev, to: coord)
                let speedMps = assumedSpeed / 3.6
                let seconds = max(1, Int(dist / speedMps))
                currentTime.addTimeInterval(TimeInterval(seconds))
            }
            previous = coord

            gpx += """
                <wpt lat="\(coord.latitude)" lon="\(coord.longitude)">
                    <time>\(formatter.string(from: currentTime))</time>
                </wpt>
                """
        }

        gpx += "\n</gpx>\n"
        return gpx
    }

    private func sampledCoordinates(from polyline: MKPolyline, maxPoints: Int) -> [CLLocationCoordinate2D] {
        let count = polyline.pointCount
        guard count > 0 else { return [] }
        let points = polyline.points()
        var coords: [CLLocationCoordinate2D] = []
        coords.reserveCapacity(min(count, maxPoints))
        if count <= maxPoints {
            for i in 0..<count { coords.append(points[i].coordinate) }
            return coords
        }
        let step = max(1, count / maxPoints)
        var i = 0
        while i < count {
            coords.append(points[i].coordinate)
            i += step
        }
        // Ensure last point is included
        if coords.last?.latitude != points[count - 1].coordinate.latitude || coords.last?.longitude != points[count - 1].coordinate.longitude {
            coords.append(points[count - 1].coordinate)
        }
        return coords
    }

    private func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }

    private func exportWaypointGPX() {
        // Prefer end if set, otherwise use start
        let coordinate = selectedEndLocation ?? selectedStartLocation
        guard let point = coordinate else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let timestamp = formatter.string(from: Date())

        let name = !singleAddress.isEmpty ? singleAddress : (!endAddress.isEmpty ? endAddress : (!startAddress.isEmpty ? startAddress : "Waypoint"))
        let shortName = (name.components(separatedBy: ",").first ?? name).replacingOccurrences(of: " ", with: "_")

        let gpx = """
            <?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <gpx version=\"1.1\" creator=\"GPX Creator\" xmlns=\"http://www.topografix.com/GPX/1/1\"> 
                <wpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\"> 
                    <name>\(name)</name> 
                    <time>\(timestamp)</time> 
                </wpt> 
            </gpx>
            """

        DispatchQueue.main.async {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType(filenameExtension: "gpx") ?? .xml]
            savePanel.nameFieldStringValue = "\(shortName).gpx"
            savePanel.title = "Save GPX Waypoint"
            savePanel.begin { result in
                if result == .OK, let url = savePanel.url {
                    do {
                        try gpx.write(to: url, atomically: true, encoding: .utf8)
                        print("GPX waypoint saved to: \(url.path)")
                    } catch {
                        print("Error saving GPX waypoint: \(error)")
                    }
                }
            }
        }
    }
}

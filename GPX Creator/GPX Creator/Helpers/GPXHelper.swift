import CoreLocation
import Foundation
import LocationHelperCore
import MapKit

/// A utility struct for generating GPX XML content and related metadata.
public struct GPXHelper {

    /// Generates a complete GPX XML string for a given route.
    /// - Parameters:
    ///   - route: The MKRoute to convert.
    ///   - simulationSpeed: The speed in km/h for timestamp calculation.
    ///   - startAddress: Optional display name for the start point.
    ///   - endAddress: Optional display name for the end point.
    /// - Returns: A GPX XML string.
    public static func generateRouteGPX(
        route: MKRoute,
        simulationSpeed: Double,
        startAddress: String,
        endAddress: String
    ) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        var currentTime = Date()

        let coordinates = CoordinateUtils.sampledCoordinates(from: route.polyline, maxPoints: 200)

        let startName = startAddress.isEmpty ? "Start" : startAddress
        let endName = endAddress.isEmpty ? "End" : endAddress

        var gpxLines: [String] = []
        gpxLines.reserveCapacity(coordinates.count + 10)

        gpxLines.append("<?xml version=\"1.0\"?>")
        gpxLines.append("<gpx version=\"1.1\" creator=\"GPX Creator • Bandan Kumar Mahto\">")
        gpxLines.append("    <metadata>")
        gpxLines.append("        <name>Route from \(startName) to \(endName)</name>")
        gpxLines.append("        <time>\(formatter.string(from: currentTime))</time>")
        gpxLines.append("    </metadata>")

        var previous: CLLocationCoordinate2D?
        for coord in coordinates {
            if let prev = previous {
                let dist = CoordinateUtils.distanceMeters(from: prev, to: coord)
                let speedMps = simulationSpeed / 3.6
                let seconds = max(1, Int(dist / speedMps))
                currentTime.addTimeInterval(TimeInterval(seconds))
            }
            previous = coord

            gpxLines.append("    <wpt lat=\"\(coord.latitude)\" lon=\"\(coord.longitude)\">")
            gpxLines.append("        <time>\(formatter.string(from: currentTime))</time>")
            gpxLines.append("    </wpt>")
        }

        gpxLines.append("</gpx>")

        return gpxLines.joined(separator: "\n")
    }

    /// Generates a single-point GPX waypoint file.
    /// - Parameters:
    ///   - coordinate: The coordinate of the waypoint.
    ///   - name: The name/address of the waypoint.
    /// - Returns: A GPX XML string.
    public static func generateWaypointGPX(coordinate: CLLocationCoordinate2D, name: String) -> String {
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

    /// Creates a suggested filename for a route.
    public static func createRouteFilename(start: String, end: String) -> String {
        let startPart = start.components(separatedBy: ",").first ?? start
        let endPart = end.components(separatedBy: ",").first ?? end
        return "\(startPart)_to_\(endPart)".replacingOccurrences(of: " ", with: "_").trimmingCharacters(in: .punctuationCharacters)
    }

    /// Creates a suggested filename for a waypoint.
    public static func createWaypointFilename(for address: String) -> String {
        let cleanName = address.components(separatedBy: ",").first ?? address
        return cleanName.replacingOccurrences(of: " ", with: "_").trimmingCharacters(in: .punctuationCharacters)
    }
}

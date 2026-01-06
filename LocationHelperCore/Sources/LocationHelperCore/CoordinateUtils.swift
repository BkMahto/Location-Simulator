import CoreLocation
import MapKit

/// A collection of utility functions for handling geographic coordinates and polylines.
public struct CoordinateUtils {

    /// Calculates the distance in meters between two coordinates.
    /// - Parameters:
    ///   - a: The first coordinate.
    ///   - b: The second coordinate.
    /// - Returns: The distance in meters.
    public static func distanceMeters(from a: CLLocationCoordinate2D, to b: CLLocationCoordinate2D) -> Double {
        let locA = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let locB = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return locA.distance(from: locB)
    }

    /// Calculates the total distance of a polyline in meters.
    /// - Parameter polyline: The polyline to measure.
    /// - Returns: The total distance in meters.
    public static func calculatePolylineDistance(_ polyline: MKPolyline) -> Double {
        let points = polyline.points()
        let count = polyline.pointCount
        var totalDistance: Double = 0

        for i in 1..<count {
            totalDistance += distanceMeters(from: points[i - 1].coordinate, to: points[i].coordinate)
        }

        return totalDistance
    }

    /// Samples coordinates from a polyline to create a manageable number of points for GPX export.
    /// - Parameters:
    ///   - polyline: The source polyline.
    ///   - maxPoints: The maximum number of points to include in the output.
    /// - Returns: An array of sampled coordinates.
    public static func sampledCoordinates(from polyline: MKPolyline, maxPoints: Int) -> [CLLocationCoordinate2D] {
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
        let targetSegmentDistance = totalDistance / Double(maxPoints - 1)

        var currentDistance: Double = 0

        for i in 1..<count {
            let segmentDistance = distanceMeters(from: points[i - 1].coordinate, to: points[i].coordinate)
            currentDistance += segmentDistance

            if currentDistance >= targetSegmentDistance || i == count - 1 {
                let currentCoord = points[i].coordinate
                if coords.last?.latitude != currentCoord.latitude || coords.last?.longitude != currentCoord.longitude {
                    coords.append(currentCoord)
                }
                currentDistance = 0

                if coords.count >= maxPoints - 1 && i < count - 1 {
                    break
                }
            }
        }

        let lastCoord = points[count - 1].coordinate
        if coords.last?.latitude != lastCoord.latitude || coords.last?.longitude != lastCoord.longitude {
            coords.append(lastCoord)
        }

        return coords
    }

    /// Checks if a coordinate is valid.
    /// - Parameter coordinate: The coordinate to validate.
    /// - Returns: True if the coordinate is valid.
    public static func isValid(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return CLLocationCoordinate2DIsValid(coordinate)
    }
}

//
//  Errors.swift
//  GPX Creator
//
//  Created by Bandan.K on 15/09/25.
//

import Foundation

/// Represents specific errors that can occur during the GPX creation process.
enum GPXError: LocalizedError {
    case routeCalculationFailed(String)
    case locationSearchFailed(String)
    case reverseGeocodingFailed(String)
    case fileSaveFailed(String)
    case invalidCoordinates(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .routeCalculationFailed(let details):
            return "Route calculation failed: \(details)"
        case .locationSearchFailed(let details):
            return "Location search failed: \(details)"
        case .reverseGeocodingFailed(let details):
            return "Address lookup failed: \(details)"
        case .fileSaveFailed(let details):
            return "Failed to save file: \(details)"
        case .invalidCoordinates(let details):
            return "Invalid coordinates: \(details)"
        case .networkError(let details):
            return "Network error: \(details)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .routeCalculationFailed:
            return "Try selecting different start and end points, or check your internet connection."
        case .locationSearchFailed:
            return "Try a different search term or check your internet connection."
        case .reverseGeocodingFailed:
            return "The selected location's address could not be determined."
        case .fileSaveFailed:
            return "Check that you have write permissions and try saving to a different location."
        case .invalidCoordinates:
            return "Please select valid locations on the map."
        case .networkError:
            return "Check your internet connection and try again."
        }
    }
}

/// High-level warnings or notifications for the user that do not necessarily block execution.
enum GPXWarning: String {
    case noRouteCalculated = "No route calculated yet. Select start and end points first."
    case noLocationSelected = "No location selected. Click on the map or search for a location."
    case simulationSpeedAdjusted = "Simulation speed adjusted to recommended range (20-100 km/h)."
    case searchResultsLimited = "Showing first 5 search results. Refine your search for more specific results."
}

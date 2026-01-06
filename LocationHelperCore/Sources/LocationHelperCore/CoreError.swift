import Foundation

/// Represents common location-related errors shared across the platform components.
public enum CoreLocationError: LocalizedError {
    case unauthorized
    case locationNotFound
    case servicesUnavailable
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Location access is not authorized. Please check your system settings."
        case .locationNotFound:
            return "The current location could not be determined."
        case .servicesUnavailable:
            return "Location services are currently unavailable on this device."
        case .custom(let message):
            return message
        }
    }
}

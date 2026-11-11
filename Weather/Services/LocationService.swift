import CoreLocation
import Foundation

struct Coordinate: Sendable {
    let latitude: Double
    let longitude: Double
}

enum LocationError: LocalizedError, Sendable {
    case denied
    case unavailable
    case timedOut

    var errorDescription: String? {
        switch self {
        case .denied: "Location access is turned off. Enable it in Settings or search for a city instead."
        case .unavailable: "Your location could not be determined."
        case .timedOut: "Finding your location took too long. Try again or search for a city."
        }
    }
}

/// One-shot location lookup built on the modern async `CLLocationUpdate` API.
struct LocationService: Sendable {
    func currentCoordinate() async throws -> Coordinate {
        try await withThrowingTaskGroup(of: Coordinate.self) { group in
            group.addTask {
                for try await update in CLLocationUpdate.liveUpdates() {
                    if update.authorizationDenied || update.authorizationDeniedGlobally || update.authorizationRestricted {
                        throw LocationError.denied
                    }
                    if let location = update.location {
                        return Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    }
                }
                throw LocationError.unavailable
            }
            group.addTask {
                try await Task.sleep(for: .seconds(20))
                throw LocationError.timedOut
            }
            guard let coordinate = try await group.next() else { throw LocationError.unavailable }
            group.cancelAll()
            return coordinate
        }
    }

    /// Best-effort human readable name for a coordinate; returns nil when reverse geocoding fails.
    func placeName(for coordinate: Coordinate) async -> String? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else { return nil }
        return placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea ?? placemark.name
    }
}

import Foundation

/// A named location, either from the geocoding search or the device's current position.
struct Place: Codable, Identifiable, Hashable, Sendable {
    static let currentLocationID = -1

    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String?
    let admin1: String?

    var isCurrentLocation: Bool { id == Place.currentLocationID }

    var subtitle: String {
        [admin1, country].compactMap { $0 }.joined(separator: ", ")
    }

    static func currentLocation(name: String, latitude: Double, longitude: Double) -> Place {
        Place(id: currentLocationID, name: name, latitude: latitude, longitude: longitude, country: nil, admin1: nil)
    }
}

struct GeocodingResponse: Decodable {
    let results: [Place]?
}

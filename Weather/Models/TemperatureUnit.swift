import Foundation

enum TemperatureUnit: String, Codable, CaseIterable, Sendable {
    case celsius
    case fahrenheit

    /// Picks Fahrenheit for US locales, Celsius everywhere else.
    static var `default`: TemperatureUnit {
        Locale.current.measurementSystem == .us ? .fahrenheit : .celsius
    }

    var symbol: String {
        switch self {
        case .celsius: "°C"
        case .fahrenheit: "°F"
        }
    }

    var apiValue: String { rawValue }

    var windSpeedAPIValue: String {
        switch self {
        case .celsius: "kmh"
        case .fahrenheit: "mph"
        }
    }

    var windSpeedLabel: String {
        switch self {
        case .celsius: "km/h"
        case .fahrenheit: "mph"
        }
    }

    var toggled: TemperatureUnit {
        self == .celsius ? .fahrenheit : .celsius
    }
}

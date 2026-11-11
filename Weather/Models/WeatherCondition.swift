import Foundation

/// Weather condition derived from a WMO weather interpretation code (as used by Open-Meteo).
enum WeatherCondition: String, Codable, Sendable, Equatable, Hashable {
    case clear
    case mainlyClear
    case partlyCloudy
    case overcast
    case fog
    case drizzle
    case freezingDrizzle
    case rain
    case heavyRain
    case freezingRain
    case showers
    case snow
    case snowShowers
    case thunderstorm
    case thunderstormHail

    init(code: Int) {
        switch code {
        case 0: self = .clear
        case 1: self = .mainlyClear
        case 2: self = .partlyCloudy
        case 3: self = .overcast
        case 45, 48: self = .fog
        case 51, 53, 55: self = .drizzle
        case 56, 57: self = .freezingDrizzle
        case 61, 63: self = .rain
        case 65, 82: self = .heavyRain
        case 66, 67: self = .freezingRain
        case 80, 81: self = .showers
        case 71, 73, 75, 77: self = .snow
        case 85, 86: self = .snowShowers
        case 95: self = .thunderstorm
        case 96, 99: self = .thunderstormHail
        default: self = .overcast
        }
    }

    var label: String {
        switch self {
        case .clear: "Clear"
        case .mainlyClear: "Mostly Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .overcast: "Overcast"
        case .fog: "Foggy"
        case .drizzle: "Drizzle"
        case .freezingDrizzle: "Freezing Drizzle"
        case .rain: "Rain"
        case .heavyRain: "Heavy Rain"
        case .freezingRain: "Freezing Rain"
        case .showers: "Showers"
        case .snow: "Snow"
        case .snowShowers: "Snow Showers"
        case .thunderstorm: "Thunderstorm"
        case .thunderstormHail: "Thunderstorm with Hail"
        }
    }

    func symbolName(isDay: Bool) -> String {
        switch self {
        case .clear: isDay ? "sun.max.fill" : "moon.stars.fill"
        case .mainlyClear: isDay ? "sun.min.fill" : "moon.fill"
        case .partlyCloudy: isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .overcast: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .freezingDrizzle, .freezingRain: "cloud.sleet.fill"
        case .rain: "cloud.rain.fill"
        case .heavyRain: "cloud.heavyrain.fill"
        case .showers: isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case .snow, .snowShowers: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .thunderstormHail: "cloud.hail.fill"
        }
    }

    /// Groups conditions into a small set of visual moods used for the background gradient.
    var mood: Mood {
        switch self {
        case .clear, .mainlyClear: .clear
        case .partlyCloudy: .partlyCloudy
        case .overcast, .fog: .overcast
        case .drizzle, .freezingDrizzle, .rain, .heavyRain, .freezingRain, .showers: .rain
        case .snow, .snowShowers: .snow
        case .thunderstorm, .thunderstormHail: .storm
        }
    }

    enum Mood: Sendable, Equatable, Hashable {
        case clear, partlyCloudy, overcast, rain, snow, storm
    }
}

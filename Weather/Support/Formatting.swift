import Foundation
import SwiftUI

extension Double {
    /// Whole-degree string such as "21°".
    var degrees: String {
        "\(Int(rounded()))°"
    }
}

enum Formatting {
    static func hour(_ date: Date, in timeZone: TimeZone) -> String {
        date.formatted(Date.FormatStyle(timeZone: timeZone).hour(.defaultDigits(amPM: .abbreviated)))
    }

    static func time(_ date: Date, in timeZone: TimeZone) -> String {
        date.formatted(Date.FormatStyle(timeZone: timeZone).hour().minute())
    }

    static func weekday(_ date: Date, in timeZone: TimeZone) -> String {
        date.formatted(Date.FormatStyle(timeZone: timeZone).weekday(.abbreviated))
    }

    static func compass(_ degrees: Int) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((Double(degrees) / 45.0).rounded()) % directions.count
        return directions[(index + directions.count) % directions.count]
    }

    static func uvDescription(_ index: Double) -> String {
        switch index {
        case ..<3: "Low"
        case ..<6: "Moderate"
        case ..<8: "High"
        case ..<11: "Very High"
        default: "Extreme"
        }
    }
}

extension WeatherCondition.Mood {
    func gradientColors(isDay: Bool) -> [Color] {
        switch (self, isDay) {
        case (.clear, true):
            [Color(red: 0.22, green: 0.53, blue: 0.94), Color(red: 0.56, green: 0.79, blue: 0.98)]
        case (.clear, false):
            [Color(red: 0.04, green: 0.07, blue: 0.24), Color(red: 0.16, green: 0.22, blue: 0.46)]
        case (.partlyCloudy, true):
            [Color(red: 0.30, green: 0.54, blue: 0.86), Color(red: 0.62, green: 0.75, blue: 0.90)]
        case (.partlyCloudy, false):
            [Color(red: 0.07, green: 0.10, blue: 0.23), Color(red: 0.23, green: 0.28, blue: 0.42)]
        case (.overcast, true):
            [Color(red: 0.40, green: 0.48, blue: 0.58), Color(red: 0.62, green: 0.68, blue: 0.76)]
        case (.overcast, false):
            [Color(red: 0.11, green: 0.13, blue: 0.19), Color(red: 0.27, green: 0.30, blue: 0.37)]
        case (.rain, true):
            [Color(red: 0.25, green: 0.34, blue: 0.48), Color(red: 0.45, green: 0.55, blue: 0.68)]
        case (.rain, false):
            [Color(red: 0.07, green: 0.10, blue: 0.19), Color(red: 0.20, green: 0.25, blue: 0.36)]
        case (.snow, true):
            [Color(red: 0.45, green: 0.58, blue: 0.73), Color(red: 0.68, green: 0.78, blue: 0.88)]
        case (.snow, false):
            [Color(red: 0.14, green: 0.19, blue: 0.31), Color(red: 0.30, green: 0.36, blue: 0.49)]
        case (.storm, true):
            [Color(red: 0.19, green: 0.20, blue: 0.34), Color(red: 0.40, green: 0.41, blue: 0.56)]
        case (.storm, false):
            [Color(red: 0.05, green: 0.05, blue: 0.14), Color(red: 0.18, green: 0.18, blue: 0.30)]
        }
    }
}

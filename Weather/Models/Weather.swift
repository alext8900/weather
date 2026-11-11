import Foundation

// MARK: - Domain model

struct Weather: Codable, Sendable {
    let timeZone: TimeZone
    let current: CurrentConditions
    let hourly: [HourForecast]
    let daily: [DayForecast]
    let fetchedAt: Date

    var today: DayForecast? { daily.first }
}

struct CurrentConditions: Codable, Sendable {
    let time: Date
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let windSpeed: Double
    let windDirection: Int
    let pressure: Double
    let cloudCover: Int
    let precipitation: Double
    let condition: WeatherCondition
    let isDay: Bool
}

struct HourForecast: Identifiable, Codable, Sendable {
    let time: Date
    let temperature: Double
    let condition: WeatherCondition
    let precipitationProbability: Int
    let isDay: Bool

    var id: Date { time }
}

struct DayForecast: Identifiable, Codable, Sendable {
    let date: Date
    let condition: WeatherCondition
    let high: Double
    let low: Double
    let sunrise: Date?
    let sunset: Date?
    let uvIndex: Double
    let precipitationProbability: Int

    var id: Date { date }
}

enum WeatherError: LocalizedError, Sendable {
    case invalidURL
    case badResponse(Int)
    case malformedData

    var errorDescription: String? {
        switch self {
        case .invalidURL: "The weather request could not be built."
        case .badResponse(let code): "The weather service responded with status \(code)."
        case .malformedData: "The weather service returned data that could not be read."
        }
    }
}

// MARK: - Open-Meteo transport model

struct ForecastResponse: Decodable {
    let timezone: String
    let current: Current
    let hourly: Hourly
    let daily: Daily

    // Explicit keys: JSONDecoder's convertFromSnakeCase maps "temperature_2m" to
    // "temperature2M" (it capitalises "2m"), so it cannot be used for these names.
    struct Current: Decodable {
        let time: String
        let temperature2m: Double
        let relativeHumidity2m: Double
        let apparentTemperature: Double
        let isDay: Int
        let precipitation: Double
        let weatherCode: Int
        let windSpeed10m: Double
        let windDirection10m: Double
        let surfacePressure: Double
        let cloudCover: Double

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case apparentTemperature = "apparent_temperature"
            case isDay = "is_day"
            case precipitation
            case weatherCode = "weather_code"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
            case surfacePressure = "surface_pressure"
            case cloudCover = "cloud_cover"
        }
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature2m: [Double?]
        let weatherCode: [Int?]
        let precipitationProbability: [Int?]
        let isDay: [Int?]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case weatherCode = "weather_code"
            case precipitationProbability = "precipitation_probability"
            case isDay = "is_day"
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let weatherCode: [Int?]
        let temperature2mMax: [Double?]
        let temperature2mMin: [Double?]
        let sunrise: [String?]
        let sunset: [String?]
        let uvIndexMax: [Double?]
        let precipitationProbabilityMax: [Int?]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case sunrise
            case sunset
            case uvIndexMax = "uv_index_max"
            case precipitationProbabilityMax = "precipitation_probability_max"
        }
    }
}

// MARK: - Mapping

extension Weather {
    init(response: ForecastResponse) throws {
        let timeZone = TimeZone(identifier: response.timezone) ?? .current

        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateTimeFormatter.timeZone = timeZone
        dateTimeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"

        guard let currentTime = dateTimeFormatter.date(from: response.current.time) else {
            throw WeatherError.malformedData
        }

        let current = CurrentConditions(
            time: currentTime,
            temperature: response.current.temperature2m,
            feelsLike: response.current.apparentTemperature,
            humidity: Int(response.current.relativeHumidity2m.rounded()),
            windSpeed: response.current.windSpeed10m,
            windDirection: Int(response.current.windDirection10m.rounded()),
            pressure: response.current.surfacePressure,
            cloudCover: Int(response.current.cloudCover.rounded()),
            precipitation: response.current.precipitation,
            condition: WeatherCondition(code: response.current.weatherCode),
            isDay: response.current.isDay == 1
        )

        var hourly: [HourForecast] = []
        let hourlyStart = currentTime.addingTimeInterval(-3600)
        for (index, rawTime) in response.hourly.time.enumerated() {
            guard let time = dateTimeFormatter.date(from: rawTime), time >= hourlyStart else { continue }
            guard let temperature = Weather.element(response.hourly.temperature2m, at: index) else { continue }
            let code = Weather.element(response.hourly.weatherCode, at: index) ?? 3
            let probability = Weather.element(response.hourly.precipitationProbability, at: index) ?? 0
            let isDay = (Weather.element(response.hourly.isDay, at: index) ?? 1) == 1
            hourly.append(HourForecast(
                time: time,
                temperature: temperature,
                condition: WeatherCondition(code: code),
                precipitationProbability: probability,
                isDay: isDay
            ))
            if hourly.count == 24 { break }
        }

        var daily: [DayForecast] = []
        for (index, rawDate) in response.daily.time.enumerated() {
            guard let date = dateFormatter.date(from: rawDate) else { continue }
            guard let high = Weather.element(response.daily.temperature2mMax, at: index),
                  let low = Weather.element(response.daily.temperature2mMin, at: index) else { continue }
            let code = Weather.element(response.daily.weatherCode, at: index) ?? 3
            let sunrise = Weather.element(response.daily.sunrise, at: index).flatMap { dateTimeFormatter.date(from: $0) }
            let sunset = Weather.element(response.daily.sunset, at: index).flatMap { dateTimeFormatter.date(from: $0) }
            daily.append(DayForecast(
                date: date,
                condition: WeatherCondition(code: code),
                high: high,
                low: low,
                sunrise: sunrise,
                sunset: sunset,
                uvIndex: Weather.element(response.daily.uvIndexMax, at: index) ?? 0,
                precipitationProbability: Weather.element(response.daily.precipitationProbabilityMax, at: index) ?? 0
            ))
        }

        self.init(timeZone: timeZone, current: current, hourly: hourly, daily: daily, fetchedAt: Date())
    }

    private static func element<T>(_ array: [T?], at index: Int) -> T? {
        guard index >= 0, index < array.count else { return nil }
        return array[index]
    }
}

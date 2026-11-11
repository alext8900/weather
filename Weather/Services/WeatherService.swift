import Foundation

/// Fetches forecasts and geocoding results from Open-Meteo (no API key required).
struct WeatherService: Sendable {
    func forecast(latitude: Double, longitude: Double, unit: TemperatureUnit) async throws -> Weather {
        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else {
            throw WeatherError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current", value: [
                "temperature_2m", "relative_humidity_2m", "apparent_temperature", "is_day",
                "precipitation", "weather_code", "wind_speed_10m", "wind_direction_10m",
                "surface_pressure", "cloud_cover",
            ].joined(separator: ",")),
            URLQueryItem(name: "hourly", value: [
                "temperature_2m", "weather_code", "precipitation_probability", "is_day",
            ].joined(separator: ",")),
            URLQueryItem(name: "daily", value: [
                "weather_code", "temperature_2m_max", "temperature_2m_min", "sunrise", "sunset",
                "uv_index_max", "precipitation_probability_max",
            ].joined(separator: ",")),
            URLQueryItem(name: "temperature_unit", value: unit.apiValue),
            URLQueryItem(name: "wind_speed_unit", value: unit.windSpeedAPIValue),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
        ]
        guard let url = components.url else { throw WeatherError.invalidURL }

        let data = try await fetch(url)
        let response: ForecastResponse
        do {
            response = try JSONDecoder().decode(ForecastResponse.self, from: data)
        } catch {
            throw WeatherError.malformedData
        }
        return try Weather(response: response)
    }

    func search(_ query: String) async throws -> [Place] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        guard var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search") else {
            throw WeatherError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "count", value: "10"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components.url else { throw WeatherError.invalidURL }

        let data = try await fetch(url)
        do {
            return try JSONDecoder().decode(GeocodingResponse.self, from: data).results ?? []
        } catch {
            throw WeatherError.malformedData
        }
    }

    private func fetch(_ url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WeatherError.badResponse(http.statusCode)
        }
        return data
    }
}

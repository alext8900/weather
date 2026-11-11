import SwiftUI

struct DetailsGridView: View {
    let weather: Weather
    let unit: TemperatureUnit

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            DetailTile(
                title: "Feels Like",
                systemImage: "thermometer.medium",
                value: weather.current.feelsLike.degrees,
                detail: feelsLikeDetail
            )
            DetailTile(
                title: "Humidity",
                systemImage: "humidity.fill",
                value: "\(weather.current.humidity)%",
                detail: humidityDetail
            )
            DetailTile(
                title: "Wind",
                systemImage: "wind",
                value: "\(Int(weather.current.windSpeed.rounded())) \(unit.windSpeedLabel)",
                detail: "From the \(Formatting.compass(weather.current.windDirection))"
            )
            DetailTile(
                title: "UV Index",
                systemImage: "sun.max.fill",
                value: "\(Int(weather.today?.uvIndex.rounded() ?? 0))",
                detail: Formatting.uvDescription(weather.today?.uvIndex ?? 0)
            )
            DetailTile(
                title: "Sunrise",
                systemImage: "sunrise.fill",
                value: weather.today?.sunrise.map { Formatting.time($0, in: weather.timeZone) } ?? "—",
                detail: weather.today?.sunset.map { "Sunset \(Formatting.time($0, in: weather.timeZone))" }
            )
            DetailTile(
                title: "Precipitation",
                systemImage: "drop.fill",
                value: "\(weather.today?.precipitationProbability ?? 0)%",
                detail: "chance today"
            )
            DetailTile(
                title: "Pressure",
                systemImage: "gauge.with.dots.needle.33percent",
                value: "\(Int(weather.current.pressure.rounded())) hPa",
                detail: nil
            )
            DetailTile(
                title: "Cloud Cover",
                systemImage: "cloud.fill",
                value: "\(weather.current.cloudCover)%",
                detail: nil
            )
        }
    }

    private var feelsLikeDetail: String {
        let difference = weather.current.feelsLike - weather.current.temperature
        if difference <= -2 { return "Wind makes it feel cooler" }
        if difference >= 2 { return "Humidity makes it feel warmer" }
        return "Similar to the actual temperature"
    }

    private var humidityDetail: String {
        switch weather.current.humidity {
        case ..<30: "Dry"
        case ..<60: "Comfortable"
        case ..<80: "Humid"
        default: "Very humid"
        }
    }
}

private struct DetailTile: View {
    let title: String
    let systemImage: String
    let value: String
    let detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .foregroundStyle(.white.opacity(0.7))

            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        )
    }
}

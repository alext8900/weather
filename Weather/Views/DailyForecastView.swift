import SwiftUI

struct DailyForecastView: View {
    let days: [DayForecast]
    let timeZone: TimeZone

    private var overallLow: Double { days.map(\.low).min() ?? 0 }
    private var overallHigh: Double { days.map(\.high).max() ?? 1 }

    var body: some View {
        GlassCard(title: "7-Day Forecast", systemImage: "calendar") {
            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element.id) { item in
                    DayRow(
                        label: item.offset == 0 ? "Today" : Formatting.weekday(item.element.date, in: timeZone),
                        day: item.element,
                        overallLow: overallLow,
                        overallHigh: overallHigh
                    )
                    if item.offset < days.count - 1 {
                        Divider().overlay(.white.opacity(0.15))
                    }
                }
            }
        }
    }
}

private struct DayRow: View {
    let label: String
    let day: DayForecast
    let overallLow: Double
    let overallHigh: Double

    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.body.weight(.medium))
                .frame(width: 56, alignment: .leading)

            VStack(spacing: 2) {
                Image(systemName: day.condition.symbolName(isDay: true))
                    .symbolRenderingMode(.multicolor)
                    .font(.title3)
                if day.precipitationProbability >= 20 {
                    Text("\(day.precipitationProbability)%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.cyan)
                }
            }
            .frame(width: 36)

            Text(day.low.degrees)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 40, alignment: .trailing)

            TemperatureRangeBar(low: day.low, high: day.high, overallLow: overallLow, overallHigh: overallHigh)
                .frame(height: 6)

            Text(day.high.degrees)
                .font(.body.weight(.medium))
                .frame(width: 40, alignment: .leading)
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10)
    }
}

/// Horizontal bar showing where a day's range sits within the week's overall range.
private struct TemperatureRangeBar: View {
    let low: Double
    let high: Double
    let overallLow: Double
    let overallHigh: Double

    var body: some View {
        GeometryReader { geometry in
            let span = Swift.max(overallHigh - overallLow, 1)
            let start = Swift.max(0, (low - overallLow) / span)
            let end = Swift.min(1, (high - overallLow) / span)
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.2))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.cyan, .green, .yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: Swift.max(8, width * (end - start)))
                    .offset(x: width * start)
            }
        }
    }
}

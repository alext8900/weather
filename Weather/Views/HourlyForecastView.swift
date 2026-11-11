import SwiftUI

struct HourlyForecastView: View {
    let hours: [HourForecast]
    let timeZone: TimeZone

    var body: some View {
        GlassCard(title: "Hourly Forecast", systemImage: "clock") {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(Array(hours.enumerated()), id: \.element.id) { item in
                        HourColumn(
                            label: item.offset == 0 ? "Now" : Formatting.hour(item.element.time, in: timeZone),
                            hour: item.element
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct HourColumn: View {
    let label: String
    let hour: HourForecast

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))

            Image(systemName: hour.condition.symbolName(isDay: hour.isDay))
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .frame(height: 30)

            Text(hour.precipitationProbability >= 10 ? "\(hour.precipitationProbability)%" : " ")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.cyan)

            Text(hour.temperature.degrees)
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(minWidth: 44)
    }
}

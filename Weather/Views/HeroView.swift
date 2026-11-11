import SwiftUI

/// Large headline: place name, temperature, condition, and today's range.
struct HeroView: View {
    let place: Place
    let weather: Weather

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                if place.isCurrentLocation {
                    Image(systemName: "location.fill")
                        .font(.subheadline)
                }
                Text(place.name)
                    .font(.title.weight(.medium))
            }

            Text(weather.current.temperature.degrees)
                .font(.system(size: 104, weight: .thin, design: .rounded))
                .contentTransition(.numericText())
                .padding(.leading, 18) // optically centre the degree glyph

            HStack(spacing: 8) {
                Image(systemName: weather.current.condition.symbolName(isDay: weather.current.isDay))
                    .symbolRenderingMode(.multicolor)
                Text(weather.current.condition.label)
            }
            .font(.title3.weight(.medium))

            if let today = weather.today {
                HStack(spacing: 14) {
                    Text("H: \(today.high.degrees)")
                    Text("L: \(today.low.degrees)")
                }
                .font(.headline)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        .padding(.top, 24)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }
}

import SwiftUI

/// Full-screen gradient that shifts with the current conditions and time of day.
struct WeatherBackground: View {
    let condition: WeatherCondition
    let isDay: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: condition.mood.gradientColors(isDay: isDay),
                startPoint: .top,
                endPoint: .bottom
            )

            // Soft glow in the upper corner: a sun by day, a cool moonlight by night.
            Circle()
                .fill(isDay ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 140, y: -300)
        }
        .animation(.easeInOut(duration: 1.0), value: condition.mood)
        .animation(.easeInOut(duration: 1.0), value: isDay)
    }
}

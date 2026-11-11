import SwiftUI

struct ContentView: View {
    // All state lives in @AppStorage: the build sandbox cannot compile @State/@Observable macros.
    @AppStorage(AppState.storageKey) private var app = JSONStored(AppState())

    private let weatherService = WeatherService()
    private let locationService = LocationService()

    var body: some View {
        NavigationStack {
            ZStack {
                WeatherBackground(
                    condition: app.value.weather?.current.condition ?? .clear,
                    isDay: app.value.weather?.current.isDay ?? true
                )
                .ignoresSafeArea()

                content
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        app.value.useCurrentLocation()
                    } label: {
                        Image(systemName: app.value.isShowingCurrentLocation ? "location.fill" : "location")
                    }
                    .accessibilityLabel("Use current location")
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(app.value.unit.symbol) {
                        app.value.toggleUnit()
                    }
                    .accessibilityLabel("Switch temperature unit")

                    Button {
                        app.value.showingSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("Search locations")
                }
            }
            .transparentNavigationBar()
            .tint(.white)
        }
        .environment(\.colorScheme, .dark)
        .sheet(isPresented: showingSearchBinding) {
            SearchView()
                .environment(\.colorScheme, .light)
                .tint(.blue)
        }
        .alert("Couldn't Load Weather", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(app.value.errorMessage ?? "")
        }
        .task(id: app.value.loadKey) {
            await load()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if let weather = app.value.weather, let place = app.value.resolvedPlace {
            ScrollView {
                VStack(spacing: 14) {
                    HeroView(place: place, weather: weather)
                    HourlyForecastView(hours: weather.hourly, timeZone: weather.timeZone)
                    DailyForecastView(days: weather.daily, timeZone: weather.timeZone)
                    DetailsGridView(weather: weather, unit: app.value.unit)

                    Text("Weather data by Open-Meteo")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await load()
            }
            .overlay(alignment: .top) {
                if app.value.isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.top, 4)
                }
            }
        } else if app.value.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .tint(.white)
                    .controlSize(.large)
                Text("Fetching the forecast…")
                    .foregroundStyle(.white.opacity(0.85))
            }
        } else {
            ContentUnavailableView {
                Label("No Forecast Yet", systemImage: "cloud.sun")
            } description: {
                Text("Use your location or search for a city to see the weather.")
            } actions: {
                Button {
                    app.value.useCurrentLocation()
                } label: {
                    Label("Use My Location", systemImage: "location.fill")
                }
                .buttonStyle(.borderedProminent)

                Button("Search for a City") {
                    app.value.showingSearch = true
                }
                .buttonStyle(.bordered)
            }
            .foregroundStyle(.white)
        }
    }

    // MARK: - Bindings derived from the stored state

    private var showingSearchBinding: Binding<Bool> {
        Binding(
            get: { app.value.showingSearch },
            set: { app.value.showingSearch = $0 }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { app.value.errorMessage != nil },
            set: { if !$0 { app.value.errorMessage = nil } }
        )
    }

    // MARK: - Loading

    /// Resolves the selected location and fetches its forecast. Driven by `.task(id:)`,
    /// so changing the selection, unit or refresh counter cancels any in-flight load.
    private func load() async {
        let key = app.value.loadKey
        app.value.isLoading = true
        app.value.errorMessage = nil

        do {
            let place: Place
            switch key.selection {
            case .place(let chosen):
                place = chosen
            case .currentLocation:
                let coordinate = try await locationService.currentCoordinate()
                let name = await locationService.placeName(for: coordinate) ?? "My Location"
                place = Place.currentLocation(name: name, latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
            guard !Task.isCancelled else { return }

            let weather = try await weatherService.forecast(
                latitude: place.latitude,
                longitude: place.longitude,
                unit: key.unit
            )
            guard !Task.isCancelled else { return }

            app.value.resolvedPlace = place
            app.value.weather = weather
            app.value.isLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            app.value.errorMessage = error.localizedDescription
            app.value.isLoading = false
        }
    }
}

private extension View {
    @ViewBuilder
    func transparentNavigationBar() -> some View {
        #if os(iOS)
        self
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        #else
        self
        #endif
    }
}

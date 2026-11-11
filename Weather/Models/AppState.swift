import Foundation

/// What the user asked to see: their current position or a chosen place.
enum LocationSelection: Codable, Equatable, Sendable {
    case currentLocation
    case place(Place)
}

/// Changes to this key start a fresh forecast load (see `ContentView`).
struct LoadKey: Equatable, Sendable {
    let selection: LocationSelection
    let unit: TemperatureUnit
    let refreshCount: Int
}

/// Entire UI state of the app. Stored as JSON in `@AppStorage` (see `JSONStored`)
/// because the build sandbox cannot compile macro-based state such as `@State`.
struct AppState: Codable, Sendable {
    static let storageKey = "appState.v1"

    var selection: LocationSelection = .currentLocation
    var unit: TemperatureUnit = TemperatureUnit.default
    var savedPlaces: [Place] = []
    var refreshCount: Int = 0

    /// The place whose weather is displayed. For `.currentLocation` this is filled in after geocoding.
    var resolvedPlace: Place? = nil
    var weather: Weather? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    var showingSearch: Bool = false
    var searchQuery: String = ""
    var searchResults: [Place] = []
    var searchFailed: Bool = false

    var loadKey: LoadKey {
        LoadKey(selection: selection, unit: unit, refreshCount: refreshCount)
    }

    var isShowingCurrentLocation: Bool {
        if case .currentLocation = selection { return true }
        return false
    }

    // MARK: - Intents

    mutating func select(_ place: Place) {
        selection = .place(place)
        showingSearch = false
    }

    mutating func useCurrentLocation() {
        if isShowingCurrentLocation {
            refreshCount += 1
        } else {
            selection = .currentLocation
        }
        showingSearch = false
    }

    mutating func toggleUnit() {
        unit = unit.toggled
    }

    func isSaved(_ place: Place) -> Bool {
        savedPlaces.contains { $0.id == place.id }
    }

    mutating func save(_ place: Place) {
        guard !place.isCurrentLocation, !isSaved(place) else { return }
        savedPlaces.append(place)
    }

    mutating func removeSavedPlaces(at offsets: IndexSet) {
        savedPlaces.remove(atOffsets: offsets)
    }
}

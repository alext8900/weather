import SwiftUI

/// City search with saved locations. Presented as a sheet from the main screen.
/// Shares the app's single `@AppStorage` state with `ContentView` (no macros available).
struct SearchView: View {
    @AppStorage(AppState.storageKey) private var app = JSONStored(AppState())

    private let service = WeatherService()

    var body: some View {
        NavigationStack {
            List {
                if trimmedQuery.isEmpty {
                    savedSection
                } else {
                    resultsSection
                }
            }
            .navigationTitle("Locations")
            .searchable(text: queryBinding, prompt: "Search for a city")
            .task(id: trimmedQuery) { await search() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { app.value.showingSearch = false }
                }
            }
        }
    }

    private var trimmedQuery: String {
        app.value.searchQuery.trimmingCharacters(in: .whitespaces)
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { app.value.searchQuery },
            set: { app.value.searchQuery = $0 }
        )
    }

    @ViewBuilder
    private var savedSection: some View {
        Section {
            Button {
                app.value.useCurrentLocation()
            } label: {
                Label("Current Location", systemImage: "location.fill")
            }
        }

        Section("Saved") {
            if app.value.savedPlaces.isEmpty {
                Text("Search for a city and tap it to save it here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(app.value.savedPlaces) { place in
                    Button {
                        app.value.select(place)
                    } label: {
                        PlaceRow(place: place, isCurrent: app.value.selection == .place(place))
                    }
                }
                .onDelete { offsets in
                    app.value.removeSavedPlaces(at: offsets)
                }
            }
        }
    }

    @ViewBuilder
    private var resultsSection: some View {
        Section {
            if app.value.searchFailed {
                Text("Search is unavailable right now.").foregroundStyle(.secondary)
            } else if app.value.searchResults.isEmpty {
                HStack {
                    ProgressView()
                    Text("Searching…").foregroundStyle(.secondary)
                }
            }

            ForEach(app.value.searchResults) { place in
                Button {
                    app.value.save(place)
                    app.value.select(place)
                } label: {
                    PlaceRow(place: place, isCurrent: false)
                }
            }
        }
    }

    private func search() async {
        let query = trimmedQuery
        guard query.count >= 2 else {
            app.value.searchResults = []
            app.value.searchFailed = false
            return
        }
        app.value.searchFailed = false
        do {
            try await Task.sleep(for: .milliseconds(300)) // debounce typing
        } catch {
            return
        }
        do {
            let places = try await service.search(query)
            guard !Task.isCancelled else { return }
            app.value.searchResults = places
        } catch {
            guard !Task.isCancelled else { return }
            app.value.searchResults = []
            app.value.searchFailed = true
        }
    }
}

private struct PlaceRow: View {
    let place: Place
    let isCurrent: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .foregroundStyle(.primary)
                if !place.subtitle.isEmpty {
                    Text(place.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if isCurrent {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }
}

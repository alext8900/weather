import Foundation

/// Wraps any Codable value as a String-backed RawRepresentable so it can live in `@AppStorage`.
///
/// The build sandbox used for this project cannot run Swift macro plugins, so `@State`
/// and `@Observable` are unavailable; all view state is kept in `@AppStorage` instead.
/// This wrapper is deliberately NOT Codable itself: a type that is both Codable and
/// RawRepresentable would encode `rawValue`, which encodes `self`, forever.
struct JSONStored<Value: Codable>: RawRepresentable {
    typealias RawValue = String

    var value: Value

    init(_ value: Value) {
        self.value = value
    }

    var rawValue: String {
        guard let data = try? JSONEncoder().encode(value) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    init?(rawValue: String) {
        guard !rawValue.isEmpty,
              let decoded = try? JSONDecoder().decode(Value.self, from: Data(rawValue.utf8)) else {
            return nil
        }
        value = decoded
    }
}

import Foundation

/// Shared state type for issues and pull requests.
/// Used for filtering in list views and passing state to services.
/// Models keep `state: String` for safe decoding of unexpected API values.
enum ItemState: String, Sendable, CaseIterable {
    case open
    case closed
    case all

    var displayName: String {
        rawValue.capitalized
    }
}

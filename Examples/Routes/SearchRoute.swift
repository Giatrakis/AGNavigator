import Foundation

enum SearchRoute: NavigationRoute, Sendable {
    case results(query: String)
}

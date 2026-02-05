import Foundation

enum HomeRoute: NavigationRoute, Sendable {
    case detail(id: String)
    case subDetail(id: String)
}

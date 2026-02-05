import Observation
import SwiftUI

@MainActor
@Observable
final class TabAppNavigator {
    var selectedTab: AppTab = .home
    var home = Navigator<HomeRoute>()
    var search = Navigator<SearchRoute>()
    var settings = Navigator<SettingsRoute>()
    var modal = ModalPresenter<ModalRoute>()

    func changeTab(to tab: AppTab) {
        selectedTab = tab
    }

    func resetSelectedTab(animated: Bool = true) {
        switch selectedTab {
        case .home:
            home.popToRoot(animated: animated)
        case .search:
            search.popToRoot(animated: animated)
        case .settings:
            settings.popToRoot(animated: animated)
        }
    }

    func resetAllTabs(animated: Bool = true) {
        perform(animated: animated) {
            home.popToRoot(animated: true)
            search.popToRoot(animated: true)
            settings.popToRoot(animated: true)
        }
    }

    @discardableResult
    func handleDeepLink(_ url: URL, animated: Bool = true) -> Bool {
        guard let request = DeepLinkParser.parse(url: url) else { return false }
        var didHandle = false
        perform(animated: animated) {
            didHandle = applyDeepLinkRequest(request)
        }
        return didHandle
    }
}

// MARK: - Deep Link Helpers
private extension TabAppNavigator {
    func applyDeepLinkRequest(_ request: DeepLinkRequest) -> Bool {
        guard let root = request.root else { return false }

        switch root {
        case AppTab.home.rawValue:
            guard let routes = parseHomeRoutes(from: request.childPath) else { return false }
            selectedTab = .home
            home.routes = routes
            return true
        case AppTab.search.rawValue:
            guard let routes = parseSearchRoutes(from: request.childPath, data: request.data) else { return false }
            selectedTab = .search
            search.routes = routes
            return true
        case AppTab.settings.rawValue:
            guard let routes = parseSettingsRoutes(from: request.childPath) else { return false }
            selectedTab = .settings
            settings.routes = routes
            return true
        default:
            return false
        }
    }

    func parseHomeRoutes(from path: [String]) -> [HomeRoute]? {
        if path.isEmpty { return [] }
        guard path.count == 2 else { return nil }
        let key = path[0].lowercased()
        let value = path[1]

        switch key {
        case "detail":
            return [.detail(id: value)]
        case "subdetail", "sub-detail":
            return [.subDetail(id: value)]
        default:
            return nil
        }
    }

    func parseSearchRoutes(from path: [String], data: [String: String]) -> [SearchRoute]? {
        if path.isEmpty { return [] }
        guard path[0].lowercased() == "results" else { return nil }

        if path.count == 2 {
            return [.results(query: path[1])]
        }

        if path.count == 1, let query = data["query"], !query.isEmpty {
            return [.results(query: query)]
        }

        return nil
    }

    func parseSettingsRoutes(from path: [String]) -> [SettingsRoute]? {
        if path.isEmpty { return [] }
        guard path.count == 1,
              let route = SettingsRoute(rawValue: path[0].lowercased()) else {
            return nil
        }
        return [route]
    }
}

// MARK: - Animation Utilities
private extension TabAppNavigator {
    func perform(animated: Bool, _ mutation: () -> Void) {
        if animated {
            mutation()
        } else {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                mutation()
            }
        }
    }
}

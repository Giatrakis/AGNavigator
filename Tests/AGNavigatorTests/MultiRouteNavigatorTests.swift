import Testing
import SwiftUI
@testable import AGNavigator

private enum TestPathRoute: Hashable, Sendable {
    case detail(id: String)
    case subDetail(id: String)
}

private enum ExternalPathRoute: Hashable, Sendable {
    case fallback(id: String)
}

@Suite("MultiRouteNavigator")
struct MultiRouteNavigatorTests {
    @Test("navigate appends route")
    @MainActor
    func navigateAppendsRoute() {
        // Given
        let navigator = MultiRouteNavigator()

        // When
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))

        // Then
        #expect(navigator.routes.count == 1)
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == .detail(id: "home-001"))
    }

    @Test("navigate appends route with animations disabled")
    @MainActor
    func navigateAppendsRouteWithoutAnimation() {
        // Given
        let navigator = MultiRouteNavigator()

        // When
        navigator.navigate(to: TestPathRoute.detail(id: "home-002"), animated: false)

        // Then
        #expect(navigator.routes.count == 1)
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == .detail(id: "home-002"))
    }

    @Test("replace overwrites path")
    @MainActor
    func replaceOverwritesPath() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))

        // When
        navigator.replace(with: [
            TestPathRoute.detail(id: "home-100"),
            TestPathRoute.subDetail(id: "home-200"),
        ])

        // Then
        #expect(navigator.routes.count == 2)
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == .subDetail(id: "home-200"))
    }

    @Test("popLast default removes one route")
    @MainActor
    func popLastDefaultRemovesOneRoute() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "1"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "2"))

        // When
        navigator.popLast()

        // Then
        #expect(navigator.routes.count == 1)
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == .detail(id: "1"))
    }

    @Test("popLast removes N routes with clamping")
    @MainActor
    func popLastRemovesNWithClamping() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "1"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "2"))

        // When
        navigator.popLast(10)

        // Then
        #expect(navigator.routes.isEmpty)
    }

    @Test("popLast non-positive count is no-op")
    @MainActor
    func popLastNonPositiveCountIsNoOp() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "1"))
        let initialCount = navigator.routes.count

        // When
        navigator.popLast(0)

        // Then
        #expect(navigator.routes.count == initialCount)
    }

    @Test("popToRoot clears routes")
    @MainActor
    func popToRootClearsRoutes() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "1"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "2"))

        // When
        navigator.popToRoot()

        // Then
        #expect(navigator.routes.isEmpty)
    }

    @Test("popLast supports animations disabled")
    @MainActor
    func popLastSupportsAnimationsDisabled() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "1"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "2"))

        // When
        navigator.popLast(1, animated: false)

        // Then
        #expect(navigator.routes.count == 1)
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == .detail(id: "1"))
    }

    @Test("popToRoot supports animations disabled")
    @MainActor
    func popToRootSupportsAnimationsDisabled() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "1"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "2"))

        // When
        navigator.popToRoot(animated: false)

        // Then
        #expect(navigator.routes.isEmpty)
    }

    @Test("contains supports exact route and predicate")
    @MainActor
    func containsSupportsExactAndPredicate() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "nested-001"))

        // When
        let containsExact = navigator.contains(TestPathRoute.detail(id: "home-001"))
        let containsMatchingCase = navigator.contains(of: TestPathRoute.self) { route in
            if case .subDetail = route {
                return true
            }
            return false
        }

        // Then
        #expect(containsExact)
        #expect(containsMatchingCase)
    }

    @Test("contains returns false for missing route and predicate")
    @MainActor
    func containsReturnsFalseForMissingMatch() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "nested-001"))

        // When
        let missingRoute = navigator.contains(TestPathRoute.detail(id: "missing"))
        let missingPredicate = navigator.contains(of: TestPathRoute.self) { route in
            if case .detail(let id) = route {
                return id == "not-found"
            }
            return false
        }

        // Then
        #expect(!missingRoute)
        #expect(!missingPredicate)
    }

    @Test("presentedRoute returns latest route or nil on root")
    @MainActor
    func presentedRouteReturnsLatestOrNil() {
        // Given
        let navigator = MultiRouteNavigator()

        // When
        let onRoot: TestPathRoute? = navigator.presentedRoute(of: TestPathRoute.self)
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "nested-001"))
        let latest: TestPathRoute? = navigator.presentedRoute(of: TestPathRoute.self)

        // Then
        #expect(onRoot == nil)
        #expect(latest == .subDetail(id: "nested-001"))
    }

    @Test("hasPresentedRoutes reflects whether stack has elements")
    @MainActor
    func hasPresentedRoutesReflectsStackState() {
        // Given
        let navigator = MultiRouteNavigator()

        // When
        let onRoot = navigator.hasPresentedRoutes
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))
        let afterPush = navigator.hasPresentedRoutes
        navigator.popToRoot()
        let afterPopToRoot = navigator.hasPresentedRoutes

        // Then
        #expect(!onRoot)
        #expect(afterPush)
        #expect(!afterPopToRoot)
    }

    @Test("init with non-empty path preserves hasPresentedRoutes and keeps typed entries unknown")
    @MainActor
    func initWithNonEmptyPathUsesUnknownTypedEntries() {
        // Given
        var path = NavigationPath()
        path.append(TestPathRoute.detail(id: "home-001"))
        let navigator = MultiRouteNavigator(path: path)

        // When
        let latestKnown: TestPathRoute? = navigator.presentedRoute(of: TestPathRoute.self)

        // Then
        #expect(navigator.hasPresentedRoutes)
        #expect(navigator.routes.count == 1)
        #expect(latestKnown == nil)
    }

    @Test("external path growth keeps known entries and appends unknown entries")
    @MainActor
    func externalPathGrowthKeepsKnownEntries() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))
        var externalPath = navigator.routes
        externalPath.append(ExternalPathRoute.fallback(id: "external-001"))

        // When
        navigator.routes = externalPath

        // Then
        #expect(navigator.routes.count == 2)
        #expect(navigator.contains(TestPathRoute.detail(id: "home-001")))
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == .detail(id: "home-001"))
    }

    @Test("external path shrink trims typed storage")
    @MainActor
    func externalPathShrinkTrimsTypedStorage() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "nested-001"))
        var externalPath = navigator.routes
        externalPath.removeLast(1)

        // When
        navigator.routes = externalPath

        // Then
        #expect(navigator.routes.count == 1)
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == .detail(id: "home-001"))
    }

    @Test("external same-count replacement invalidates typed entries")
    @MainActor
    func externalSameCountReplacementInvalidatesTypedEntries() {
        // Given
        let navigator = MultiRouteNavigator()
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))
        navigator.navigate(to: TestPathRoute.subDetail(id: "nested-001"))
        var externalPath = NavigationPath()
        externalPath.append(ExternalPathRoute.fallback(id: "external-001"))
        externalPath.append(ExternalPathRoute.fallback(id: "external-002"))

        // When
        navigator.routes = externalPath

        // Then
        #expect(navigator.routes.count == 2)
        #expect(!navigator.contains(TestPathRoute.detail(id: "home-001")))
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == nil)
    }

    @Test("internal navigate and replace keep typed introspection")
    @MainActor
    func internalMutationsKeepTypedIntrospection() {
        // Given
        let navigator = MultiRouteNavigator()

        // When
        navigator.navigate(to: TestPathRoute.detail(id: "home-001"))
        navigator.replace(with: [
            TestPathRoute.detail(id: "home-100"),
            TestPathRoute.subDetail(id: "nested-100"),
        ])

        // Then
        #expect(navigator.contains(TestPathRoute.detail(id: "home-100")))
        #expect(navigator.presentedRoute(of: TestPathRoute.self) == .subDetail(id: "nested-100"))
    }
}

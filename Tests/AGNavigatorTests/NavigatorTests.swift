import Testing
@testable import AGNavigator

private enum TestNavigationRoute: NavigationRoute, Sendable {
    case detail(id: String)
    case subDetail(id: String)
}

@Suite("Navigator")
struct NavigatorTests {
    @Test("navigate appends route")
    @MainActor
    func navigateAppendsRoute() {
        // Given
        let navigator = Navigator<TestNavigationRoute>()

        // When
        navigator.navigate(to: .detail(id: "home-001"))

        // Then
        #expect(navigator.routes == [.detail(id: "home-001")])
    }

    @Test("navigate appends route with animations disabled")
    @MainActor
    func navigateAppendsRouteWithoutAnimation() {
        // Given
        let navigator = Navigator<TestNavigationRoute>()

        // When
        navigator.navigate(to: .detail(id: "home-002"), animated: false)

        // Then
        #expect(navigator.routes == [.detail(id: "home-002")])
    }

    @Test("replace overwrites routes")
    @MainActor
    func replaceOverwritesRoutes() {
        // Given
        let navigator = Navigator<TestNavigationRoute>(
            routes: [.detail(id: "home-001")]
        )

        // When
        navigator.replace(with: [
            .detail(id: "home-100"),
            .subDetail(id: "home-200"),
        ])

        // Then
        #expect(navigator.routes == [
            .detail(id: "home-100"),
            .subDetail(id: "home-200"),
        ])
    }

    @Test("popLast default removes one route")
    @MainActor
    func popLastDefaultRemovesOneRoute() {
        // Given
        let navigator = Navigator<TestNavigationRoute>(
            routes: [.detail(id: "1"), .subDetail(id: "2")]
        )

        // When
        navigator.popLast()

        // Then
        #expect(navigator.routes == [.detail(id: "1")])
    }

    @Test("popLast removes N routes with clamping")
    @MainActor
    func popLastRemovesNWithClamping() {
        // Given
        let navigator = Navigator<TestNavigationRoute>(
            routes: [.detail(id: "1"), .subDetail(id: "2")]
        )

        // When
        navigator.popLast(10)

        // Then
        #expect(navigator.routes.isEmpty)
    }

    @Test("popLast non-positive count is no-op")
    @MainActor
    func popLastNonPositiveCountIsNoOp() {
        // Given
        let initialRoutes: [TestNavigationRoute] = [.detail(id: "1")]
        let navigator = Navigator<TestNavigationRoute>(routes: initialRoutes)

        // When
        navigator.popLast(0)

        // Then
        #expect(navigator.routes == initialRoutes)
    }

    @Test("popToRoot clears routes")
    @MainActor
    func popToRootClearsRoutes() {
        // Given
        let navigator = Navigator<TestNavigationRoute>(
            routes: [.detail(id: "1"), .subDetail(id: "2")]
        )

        // When
        navigator.popToRoot()

        // Then
        #expect(navigator.routes.isEmpty)
    }

    @Test("popLast supports animations disabled")
    @MainActor
    func popLastSupportsAnimationsDisabled() {
        // Given
        let navigator = Navigator<TestNavigationRoute>(
            routes: [.detail(id: "1"), .subDetail(id: "2")]
        )

        // When
        navigator.popLast(1, animated: false)

        // Then
        #expect(navigator.routes == [.detail(id: "1")])
    }

    @Test("popToRoot supports animations disabled")
    @MainActor
    func popToRootSupportsAnimationsDisabled() {
        // Given
        let navigator = Navigator<TestNavigationRoute>(
            routes: [.detail(id: "1"), .subDetail(id: "2")]
        )

        // When
        navigator.popToRoot(animated: false)

        // Then
        #expect(navigator.routes.isEmpty)
    }

    @Test("contains supports exact route and predicate")
    @MainActor
    func containsSupportsExactAndPredicate() {
        // Given
        let navigator = Navigator<TestNavigationRoute>(
            routes: [.detail(id: "home-001"), .subDetail(id: "nested-001")]
        )

        // When
        let containsExact = navigator.contains(.detail(id: "home-001"))
        let containsMatchingCase = navigator.contains { route in
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
        let navigator = Navigator<TestNavigationRoute>(
            routes: [.detail(id: "home-001"), .subDetail(id: "nested-001")]
        )

        // When
        let missingRoute = navigator.contains(.detail(id: "missing"))
        let missingPredicate = navigator.contains { route in
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
        let navigator = Navigator<TestNavigationRoute>()

        // When
        let onRoot = navigator.presentedRoute
        navigator.navigate(to: .detail(id: "home-001"))
        navigator.navigate(to: .subDetail(id: "nested-001"))
        let latest = navigator.presentedRoute

        // Then
        #expect(onRoot == nil)
        #expect(latest == .subDetail(id: "nested-001"))
    }

    @Test("hasPresentedRoutes reflects whether stack has elements")
    @MainActor
    func hasPresentedRoutesReflectsStackState() {
        // Given
        let navigator = Navigator<TestNavigationRoute>()

        // When
        let onRoot = navigator.hasPresentedRoutes
        navigator.navigate(to: .detail(id: "home-001"))
        let afterPush = navigator.hasPresentedRoutes
        navigator.popToRoot()
        let afterPopToRoot = navigator.hasPresentedRoutes

        // Then
        #expect(!onRoot)
        #expect(afterPush)
        #expect(!afterPopToRoot)
    }
}

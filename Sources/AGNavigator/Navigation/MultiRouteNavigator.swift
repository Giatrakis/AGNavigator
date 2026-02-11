//
//  MultiRouteNavigator.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 6/2/26.
//

import Observation
import SwiftUI

/// A navigator that stores a `NavigationPath`, allowing a single stack to contain multiple route types.
///
/// Use this when one `NavigationStack` needs more than one `navigationDestination(for:)` type.
@MainActor
@Observable
public final class MultiRouteNavigator: MultiRouteNavigating {
    /// The path bound to `NavigationStack(path:)`.
    public var routes: NavigationPath {
        didSet(oldValue) {
            guard !isInternalMutation else { return }

            let newCount = routes.count
            let oldCount = oldValue.count
            let isNoOpAssignment = oldCount == newCount &&
                String(reflecting: oldValue) == String(reflecting: routes)

            // External mutations can come from NavigationStack bindings. We keep
            // known route values when the path shrinks and mark externally-added
            // elements as unknown placeholders.
            if newCount < storage.count {
                storage.removeLast(storage.count - newCount)
            } else if newCount > storage.count {
                storage.append(
                    contentsOf: Array(repeating: .unknown, count: newCount - storage.count)
                )
            }

            // If the count is unchanged but the path was externally replaced,
            // we cannot safely infer the typed values, so invalidate known entries.
            // Skip invalidation for no-op assignments.
            if newCount == oldCount, oldCount > 0, !isNoOpAssignment {
                storage = Array(repeating: .unknown, count: newCount)
            }
        }
    }
    private var storage: [StorageElement]
    private var isInternalMutation = false

    /// Creates an empty navigator or one seeded with an existing path.
    /// - Parameter path: The initial navigation path.
    public init(path: NavigationPath = NavigationPath()) {
        self.routes = path
        self.storage = Array(repeating: .unknown, count: path.count)
    }

    /// Creates a navigator seeded with typed routes.
    /// - Parameter routes: The initial routes to append to the path.
    public init<Route: Hashable>(routes: [Route]) {
        self.routes = NavigationPath()
        self.storage = []
        self.storage.reserveCapacity(routes.count)
        for route in routes {
            storage.append(.known(AnyHashable(route)))
            self.routes.append(route)
        }
    }

    /// Pushes a route onto the path.
    /// - Parameters:
    ///   - route: The route to append.
    ///   - animated: Whether the transition should animate. Defaults to `true`.
    public func navigate<Route: Hashable>(to route: Route, animated: Bool = true) {
        perform(animated: animated) {
            storage.append(.known(AnyHashable(route)))
            routes.append(route)
        }
    }

    /// Replaces the entire path with new routes.
    /// - Parameters:
    ///   - routes: The new routes to use.
    ///   - animated: Whether the transition should animate. Defaults to `true`.
    public func replace<Route: Hashable>(with routes: [Route], animated: Bool = true) {
        perform(animated: animated) {
            storage.removeAll(keepingCapacity: true)
            storage.reserveCapacity(routes.count)
            var newPath = NavigationPath()
            for route in routes {
                storage.append(.known(AnyHashable(route)))
                newPath.append(route)
            }
            self.routes = newPath
        }
    }

    /// Checks whether the path contains a route of the given type matching a predicate.
    /// - Parameters:
    ///   - type: The route type to search.
    ///   - predicate: A matcher for the route value.
    /// - Returns: `true` when a matching route exists.
    public func contains<Route: Hashable>(of type: Route.Type, where predicate: (Route) -> Bool) -> Bool {
        storage.contains { element in
            guard case .known(let value) = element,
                  let value = value as? Route else { return false }
            return predicate(value)
        }
    }

    /// Returns the most recently presented route of the given type.
    /// - Parameter type: The route type to search.
    /// - Returns: The latest matching route, or `nil` if none exist.
    public func presentedRoute<Route: Hashable>(of type: Route.Type) -> Route? {
        storage.reversed().compactMap { element in
            guard case .known(let value) = element else { return nil }
            return value as? Route
        }.first
    }

    /// Pops the last N routes from the path.
    /// - Parameters:
    ///   - count: The number of routes to remove. Defaults to `1`.
    ///   - animated: Whether the transition should animate. Defaults to `true`.
    public func popLast(_ count: Int = 1, animated: Bool = true) {
        guard count > 0 else { return }

        perform(animated: animated) {
            let countToRemove = min(count, routes.count)
            if countToRemove > 0 {
                storage.removeLast(min(countToRemove, storage.count))
                routes.removeLast(countToRemove)
            }
        }
    }

    /// Clears the path and returns to the root.
    /// - Parameter animated: Whether the transition should animate. Defaults to `true`.
    public func popToRoot(animated: Bool = true) {
        perform(animated: animated) {
            storage.removeAll()
            if !routes.isEmpty {
                routes.removeLast(routes.count)
            }
        }
    }
}

private extension MultiRouteNavigator {
    func perform(animated: Bool, _ mutation: () -> Void) {
        withInternalMutation {
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

    func withInternalMutation(_ mutation: () -> Void) {
        isInternalMutation = true
        defer { isInternalMutation = false }
        mutation()
    }
}

private extension MultiRouteNavigator {
    enum StorageElement {
        case known(AnyHashable)
        case unknown
    }
}

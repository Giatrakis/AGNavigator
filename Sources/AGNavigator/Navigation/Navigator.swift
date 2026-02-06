//
//  Navigator.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Observation
import SwiftUI

/// A typed navigator that manages a stack of `Route` values for `NavigationStack(path:)`.
@MainActor
@Observable
public final class Navigator<Route: NavigationRoute>: Navigating {
    /// The current navigation stack.
    public var routes: [Route]

    /// Creates a navigator seeded with routes.
    /// - Parameter routes: The initial routes for the stack.
    public init(routes: [Route] = []) {
        self.routes = routes
    }

    /// Pushes a route onto the stack.
    /// - Parameters:
    ///   - route: The route to append.
    ///   - animated: Whether the transition should animate. Defaults to `true`.
    public func navigate(to route: Route, animated: Bool = true) {
        perform(animated: animated) {
            routes.append(route)
        }
    }

    /// Replaces the entire stack with new routes.
    /// - Parameters:
    ///   - routes: The new routes to use.
    ///   - animated: Whether the transition should animate. Defaults to `true`.
    public func replace(with routes: [Route], animated: Bool = true) {
        perform(animated: animated) {
            self.routes = routes
        }
    }

    /// Checks whether the stack contains a route or a matching predicate.
    /// - Parameters:
    ///   - route: A specific route to search for.
    ///   - predicate: An optional predicate to match routes.
    /// - Returns: `true` when a match exists.
    public func contains(_ route: Route?, where predicate: ((Route) -> Bool)? = nil) -> Bool {
        if let predicate {
            return routes.contains(where: predicate)
        }
        if let route {
            return routes.contains(route)
        }
        return false
    }

    /// Pops the last N routes from the stack.
    /// - Parameters:
    ///   - count: The number of routes to remove. Defaults to `1`.
    ///   - animated: Whether the transition should animate. Defaults to `true`.
    public func popLast(_ count: Int = 1, animated: Bool = true) {
        guard count > 0 else { return }

        perform(animated: animated) {
            let countToRemove = min(count, routes.count)
            if countToRemove > 0 {
                routes.removeLast(countToRemove)
            }
        }
    }

    /// Clears the stack and returns to root.
    /// - Parameter animated: Whether the transition should animate. Defaults to `true`.
    public func popToRoot(animated: Bool = true) {
        perform(animated: animated) {
            routes.removeAll()
        }
    }
}

private extension Navigator {
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

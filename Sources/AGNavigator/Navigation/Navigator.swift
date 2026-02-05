//
//  Navigator.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Observation
import SwiftUI

@MainActor
@Observable
public final class Navigator<Route: NavigationRoute>: Navigating {
    public var routes: [Route]

    public init(routes: [Route] = []) {
        self.routes = routes
    }

    public func navigate(to route: Route, animated: Bool = true) {
        perform(animated: animated) {
            routes.append(route)
        }
    }

    public func contains(_ route: Route?, where predicate: ((Route) -> Bool)? = nil) -> Bool {
        if let predicate {
            return routes.contains(where: predicate)
        }
        if let route {
            return routes.contains(route)
        }
        return false
    }

    public func popLast(_ count: Int = 1, animated: Bool = true) {
        guard count > 0 else { return }

        perform(animated: animated) {
            let countToRemove = min(count, routes.count)
            if countToRemove > 0 {
                routes.removeLast(countToRemove)
            }
        }
    }

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

//
//  MultiRouteNavigator.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 6/2/26.
//

import Observation
import SwiftUI

@MainActor
@Observable
public final class MultiRouteNavigator: MultiRouteNavigating {
    public var routes: NavigationPath {
        didSet {
            let newCount = routes.count
            let currentCount = storage.count

            if newCount < currentCount {
                storage.removeLast(currentCount - newCount)
            } else if newCount > currentCount {
                storage.removeAll()
            }
        }
    }
    private var storage: [AnyHashable]

    public init(path: NavigationPath = NavigationPath()) {
        self.routes = path
        self.storage = []
    }

    public init<Route: Hashable>(routes: [Route]) {
        self.routes = NavigationPath()
        self.storage = []
        self.storage.reserveCapacity(routes.count)
        for route in routes {
            storage.append(route)
            self.routes.append(route)
        }
    }

    public func navigate<Route: Hashable>(to route: Route, animated: Bool = true) {
        perform(animated: animated) {
            storage.append(route)
            routes.append(route)
        }
    }

    public func replace<Route: Hashable>(with routes: [Route], animated: Bool = true) {
        perform(animated: animated) {
            storage.removeAll(keepingCapacity: true)
            storage.reserveCapacity(routes.count)
            var newPath = NavigationPath()
            for route in routes {
                storage.append(route)
                newPath.append(route)
            }
            self.routes = newPath
        }
    }

    public func contains<Route: Hashable>(of type: Route.Type, where predicate: (Route) -> Bool) -> Bool {
        storage.contains { element in
            guard let value = element as? Route else { return false }
            return predicate(value)
        }
    }

    public func presentedRoute<Route: Hashable>(of type: Route.Type) -> Route? {
        storage.reversed().compactMap { $0 as? Route }.first
    }

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

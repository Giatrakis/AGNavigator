//
//  MultiRouteNavigating.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 6/2/26.
//

import SwiftUI

@MainActor
public protocol MultiRouteNavigating: AnyObject {
    var routes: NavigationPath { get set }
    var hasPresentedRoutes: Bool { get }

    func navigate<Route: Hashable>(to route: Route, animated: Bool)
    func replace<Route: Hashable>(with routes: [Route], animated: Bool)
    func contains<Route: Hashable>(of type: Route.Type, where predicate: (Route) -> Bool) -> Bool
    func presentedRoute<Route: Hashable>(of type: Route.Type) -> Route?
    func popLast(_ count: Int, animated: Bool)
    func popToRoot(animated: Bool)
}

extension MultiRouteNavigating {
    public var hasPresentedRoutes: Bool {
        !routes.isEmpty
    }

    public func navigate<Route: Hashable>(to route: Route) {
        navigate(to: route, animated: true)
    }

    public func replace<Route: Hashable>(with routes: [Route]) {
        replace(with: routes, animated: true)
    }

    public func contains<Route: Hashable>(_ route: Route?, where predicate: ((Route) -> Bool)? = nil) -> Bool {
        if let predicate {
            return contains(of: Route.self, where: predicate)
        }
        if let route {
            return contains(of: Route.self) { $0 == route }
        }
        return false
    }

    public func contains<Route: Hashable>(_ route: Route) -> Bool {
        contains(route, where: nil)
    }

    public func contains<Route: Hashable>(where predicate: @escaping (Route) -> Bool) -> Bool {
        contains(of: Route.self, where: predicate)
    }

    public func presentedRoute<Route: Hashable>() -> Route? {
        presentedRoute(of: Route.self)
    }

    public func popLast(_ count: Int = 1) {
        popLast(count, animated: true)
    }

    public func popToRoot() {
        popToRoot(animated: true)
    }
}

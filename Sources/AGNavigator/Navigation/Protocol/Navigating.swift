//
//  Navigating.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

@MainActor
public protocol Navigating: AnyObject {
    associatedtype Route: NavigationRoute

    var routes: [Route] { get set }
    var hasPresentedRoutes: Bool { get }
    var presentedRoute: Route? { get }

    func navigate(to route: Route, animated: Bool)
    func replace(with routes: [Route], animated: Bool)
    func contains(_ route: Route?, where predicate: ((Route) -> Bool)?) -> Bool
    func popLast(_ count: Int, animated: Bool)
    func popToRoot(animated: Bool)
}

extension Navigating {
    public var hasPresentedRoutes: Bool {
        !routes.isEmpty
    }

    public var presentedRoute: Route? {
        routes.last
    }

    public func navigate(to route: Route) {
        navigate(to: route, animated: true)
    }

    public func replace(with routes: [Route]) {
        replace(with: routes, animated: true)
    }

    public func contains(_ route: Route) -> Bool {
        contains(route, where: nil)
    }

    public func contains(where predicate: @escaping (Route) -> Bool) -> Bool {
        contains(nil, where: predicate)
    }

    public func popLast(_ count: Int = 1) {
        popLast(count, animated: true)
    }

    public func popToRoot() {
        popToRoot(animated: true)
    }
}

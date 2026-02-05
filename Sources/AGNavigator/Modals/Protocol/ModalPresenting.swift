//
//  ModalPresenting.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

@MainActor
public protocol ModalPresenting: AnyObject {
    associatedtype Route: NavigationRoute

    var presentedRoute: Route? { get }
    var presentedStyle: ModalStyle? { get }
    var presentedSheet: Route? { get }
    var presentedFullScreen: Route? { get }

    func present(
        _ route: Route,
        as style: ModalStyle,
        animated: Bool,
        policy: ModalPresentationPolicy
    )
    func dismiss(animated: Bool)
}

extension ModalPresenting {
    public func present(_ route: Route) {
        present(route, as: .sheet, animated: true, policy: .replaceCurrent)
    }

    public func present(_ route: Route, as style: ModalStyle) {
        present(route, as: style, animated: true, policy: .replaceCurrent)
    }

    public func present(_ route: Route, as style: ModalStyle, animated: Bool) {
        present(route, as: style, animated: animated, policy: .replaceCurrent)
    }

    public func dismiss() {
        dismiss(animated: true)
    }
}

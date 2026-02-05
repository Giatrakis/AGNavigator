//
//  ModalPresenter.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Observation
import SwiftUI

@MainActor
@Observable
public final class ModalPresenter<Route: NavigationRoute>: ModalPresenting {
    public private(set) var presentedRoute: Route?
    public private(set) var presentedStyle: ModalStyle?

    public var presentedSheet: Route? {
        get {
            guard presentedStyle == .sheet else { return nil }
            return presentedRoute
        }
        set {
            guard let route = newValue else {
                guard presentedStyle == .sheet else { return }
                dismiss()
                return
            }
            present(route, as: .sheet, policy: .replaceCurrent)
        }
    }

    public var presentedFullScreen: Route? {
        get {
            guard presentedStyle == .fullScreen else { return nil }
            return presentedRoute
        }
        set {
            guard let route = newValue else {
                guard presentedStyle == .fullScreen else { return }
                dismiss()
                return
            }
            present(route, as: .fullScreen, policy: .replaceCurrent)
        }
    }

    public init() {}

    public func present(
        _ route: Route,
        as style: ModalStyle = .sheet,
        animated: Bool = true,
        policy: ModalPresentationPolicy = .replaceCurrent
    ) {
        if policy == .ignoreIfAlreadyPresented, presentedRoute != nil {
            return
        }

        perform(animated: animated) {
            presentedRoute = route
            presentedStyle = style
        }
    }

    public func dismiss(animated: Bool = true) {
        perform(animated: animated) {
            presentedRoute = nil
            presentedStyle = nil
        }
    }
}

private extension ModalPresenter {
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

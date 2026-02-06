//
//  ModalPresenter.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Observation
import SwiftUI

/// Manages modal presentation state for sheets and full-screen covers.
@MainActor
@Observable
public final class ModalPresenter<Route: NavigationRoute>: ModalPresenting {
    /// The currently presented modal route, if any.
    public private(set) var presentedRoute: Route?
    /// The presentation style of the current modal, if any.
    public private(set) var presentedStyle: ModalStyle?

    /// The current route when the style is `.sheet`.
    ///
    /// Bind this to `.sheet(item:)` for model-driven sheet presentation.
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

    /// The current route when the style is `.fullScreen`.
    ///
    /// Bind this to `.fullScreenCover(item:)` for model-driven full-screen presentation.
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

    /// Creates a modal presenter with no active presentation.
    public init() {}

    /// Presents a route as a sheet or full-screen cover.
    /// - Parameters:
    ///   - route: The modal route to present.
    ///   - style: The presentation style. Defaults to `.sheet`.
    ///   - animated: Whether the presentation should animate. Defaults to `true`.
    ///   - policy: How to handle an already presented modal. Defaults to `.replaceCurrent`.
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

    /// Dismisses the currently presented modal route.
    /// - Parameter animated: Whether the dismissal should animate. Defaults to `true`.
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

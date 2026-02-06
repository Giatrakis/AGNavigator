//
//  ModalPresentation.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

/// The presentation style for a modal.
public enum ModalStyle: Hashable {
    /// Presents the modal as a sheet.
    case sheet
    /// Presents the modal as a full-screen cover.
    case fullScreen
}

/// Defines how a new modal presentation should behave when one is already visible.
public enum ModalPresentationPolicy: Hashable {
    /// Replaces any currently presented modal with the new one.
    case replaceCurrent
    /// Ignores the request if a modal is already presented.
    case ignoreIfAlreadyPresented
}

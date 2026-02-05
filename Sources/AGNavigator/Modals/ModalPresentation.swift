//
//  ModalPresentation.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

public enum ModalStyle: Hashable {
    case sheet
    case fullScreen
}

public enum ModalPresentationPolicy: Hashable {
    case replaceCurrent
    case ignoreIfAlreadyPresented
}

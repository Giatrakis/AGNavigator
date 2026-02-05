//
//  DeepLinkRequest.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

public struct DeepLinkRequest: Equatable {
    public let path: [String]
    public let data: [String: String]

    public init(path: [String], data: [String: String]) {
        self.path = path
        self.data = data
    }

    public var root: String? {
        path.first?.lowercased()
    }

    public var childPath: [String] {
        Array(path.dropFirst())
    }
}

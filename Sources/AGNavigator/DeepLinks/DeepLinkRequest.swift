//
//  DeepLinkRequest.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

/// Represents a parsed deep link, including path segments and query data.
public struct DeepLinkRequest: Equatable {
    /// All path segments for the deep link (lowercasing is not applied).
    public let path: [String]
    /// Query parameters, normalized to lowercase keys.
    public let data: [String: String]

    /// Creates a deep link request.
    /// - Parameters:
    ///   - path: The ordered path segments.
    ///   - data: Query parameters as key-value pairs.
    public init(path: [String], data: [String: String]) {
        self.path = path
        self.data = data
    }

    /// The first path segment, lowercased.
    public var root: String? {
        path.first?.lowercased()
    }

    /// All path segments after `root`.
    public var childPath: [String] {
        Array(path.dropFirst())
    }
}

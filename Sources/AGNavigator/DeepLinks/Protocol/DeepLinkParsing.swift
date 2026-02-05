//
//  DeepLinkParsing.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

public protocol DeepLinkParsing {
    static func parse(url: URL) -> DeepLinkRequest?
    static func parse(urlString: String) -> DeepLinkRequest?
}

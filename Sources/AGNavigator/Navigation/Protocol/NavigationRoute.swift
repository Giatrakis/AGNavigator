//
//  NavigationRoute.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

public protocol NavigationRoute: Hashable, Identifiable {}

extension NavigationRoute {
    public var id: Self { self }
}

//
//  DeepLinkParser.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

public struct DeepLinkParser: DeepLinkParsing {
    public static func parse(url: URL) -> DeepLinkRequest? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var segments: [String] = []

        if shouldIncludeHostAsPathSegment(for: components.scheme),
           let host = components.host,
           !host.isEmpty {
            segments.append(host.removingPercentEncoding ?? host)
        }

        segments.append(contentsOf: components.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { $0.removingPercentEncoding ?? $0 })

        guard !segments.isEmpty else {
            return nil
        }

        let data = parseQueryParameters(from: components.queryItems)
        return DeepLinkRequest(
            path: segments,
            data: data
        )
    }

    public static func parse(urlString: String) -> DeepLinkRequest? {
        guard let url = URL(string: urlString) else { return nil }
        return parse(url: url)
    }
}

private extension DeepLinkParser {
    static func shouldIncludeHostAsPathSegment(for scheme: String?) -> Bool {
        guard let scheme else { return false }
        return scheme.caseInsensitiveCompare("http") != .orderedSame &&
            scheme.caseInsensitiveCompare("https") != .orderedSame
    }

    static func parseQueryParameters(from queryItems: [URLQueryItem]?) -> [String: String] {
        guard let queryItems else { return [:] }

        return queryItems.reduce(into: [String: String]()) { result, item in
            guard let value = item.value else { return }
            let normalizedName = item.name.lowercased()
            result[normalizedName] = value.removingPercentEncoding ?? value
        }
    }
}

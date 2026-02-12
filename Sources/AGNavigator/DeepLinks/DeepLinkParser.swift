//
//  DeepLinkParser.swift
//  ag-navigator
//
//  Created by "Alex Giatrakis" on 4/2/26.
//

import Foundation

/// Parses URLs into `DeepLinkRequest` values used for navigation mapping.
public struct DeepLinkParser: DeepLinkParsing {
    /// Controls how URLs are normalized during parsing.
    public struct Options: Hashable, Sendable {
        /// How duplicate query keys should be resolved.
        public enum QueryDuplicatePolicy: Hashable, Sendable {
            /// Keep the first value encountered for a query key.
            case firstWins
            /// Keep the last value encountered for a query key.
            case lastWins
        }

        /// Whether custom-scheme URLs should include host as first path segment.
        public var includeHostForCustomSchemes: Bool
        /// Whether path segments should be lowercased.
        public var normalizePathToLowercase: Bool
        /// Whether query keys should be lowercased.
        public var normalizeQueryKeysToLowercase: Bool
        /// How duplicate query keys are resolved.
        public var queryDuplicatePolicy: QueryDuplicatePolicy

        public init(
            includeHostForCustomSchemes: Bool = true,
            normalizePathToLowercase: Bool = false,
            normalizeQueryKeysToLowercase: Bool = true,
            queryDuplicatePolicy: QueryDuplicatePolicy = .lastWins
        ) {
            self.includeHostForCustomSchemes = includeHostForCustomSchemes
            self.normalizePathToLowercase = normalizePathToLowercase
            self.normalizeQueryKeysToLowercase = normalizeQueryKeysToLowercase
            self.queryDuplicatePolicy = queryDuplicatePolicy
        }

        /// Default parser behavior used by existing APIs.
        public static let `default` = Options()
    }

    /// Parses a URL into a `DeepLinkRequest`.
    ///
    /// For custom schemes, the host is included as the first path segment.
    /// For universal links, only the path segments are used.
    /// - Parameter url: The URL to parse.
    /// - Returns: A parsed request containing `path` and `data`, or `nil` if invalid.
    public static func parse(url: URL) -> DeepLinkRequest? {
        parse(url: url, options: .default)
    }

    /// Parses a URL into a `DeepLinkRequest` using custom options.
    /// - Parameters:
    ///   - url: The URL to parse.
    ///   - options: Parsing normalization and duplicate-key behavior.
    /// - Returns: A parsed request containing `path` and `data`, or `nil` if invalid.
    public static func parse(url: URL, options: Options) -> DeepLinkRequest? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var segments: [String] = []

        if options.includeHostForCustomSchemes,
           shouldIncludeHostAsPathSegment(for: components.scheme),
           let host = components.host,
           !host.isEmpty {
            let decodedHost = host.removingPercentEncoding ?? host
            segments.append(options.normalizePathToLowercase ? decodedHost.lowercased() : decodedHost)
        }

        segments.append(contentsOf: components.path
            .split(separator: "/")
            .map(String.init)
            .filter { !$0.isEmpty }
            .map { segment in
                let decoded = segment.removingPercentEncoding ?? segment
                return options.normalizePathToLowercase ? decoded.lowercased() : decoded
            })

        guard !segments.isEmpty else {
            return nil
        }

        let data = parseQueryParameters(from: components.queryItems, options: options)
        return DeepLinkRequest(
            path: segments,
            data: data
        )
    }

    /// Parses a raw URL string into a `DeepLinkRequest`.
    /// - Parameter urlString: The URL string to parse.
    /// - Returns: A parsed request containing `path` and `data`, or `nil` if invalid.
    public static func parse(urlString: String) -> DeepLinkRequest? {
        parse(urlString: urlString, options: .default)
    }

    /// Parses a raw URL string into a `DeepLinkRequest` using custom options.
    /// - Parameters:
    ///   - urlString: The URL string to parse.
    ///   - options: Parsing normalization and duplicate-key behavior.
    /// - Returns: A parsed request containing `path` and `data`, or `nil` if invalid.
    public static func parse(urlString: String, options: Options) -> DeepLinkRequest? {
        guard let url = URL(string: urlString) else { return nil }
        return parse(url: url, options: options)
    }
}

private extension DeepLinkParser {
    static func shouldIncludeHostAsPathSegment(for scheme: String?) -> Bool {
        guard let scheme else { return false }
        return scheme.caseInsensitiveCompare("http") != .orderedSame &&
            scheme.caseInsensitiveCompare("https") != .orderedSame
    }

    static func parseQueryParameters(from queryItems: [URLQueryItem]?, options: Options) -> [String: String] {
        guard let queryItems else { return [:] }

        return queryItems.reduce(into: [String: String]()) { result, item in
            guard let value = item.value else { return }
            let name = options.normalizeQueryKeysToLowercase ? item.name.lowercased() : item.name
            let decodedValue = value.removingPercentEncoding ?? value

            switch options.queryDuplicatePolicy {
            case .firstWins:
                if result[name] == nil {
                    result[name] = decodedValue
                }
            case .lastWins:
                result[name] = decodedValue
            }
        }
    }
}

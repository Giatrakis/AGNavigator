import Testing
import Foundation
@testable import AGNavigator

@Suite("DeepLinkParser")
struct DeepLinkParserTests {
    @Test("parses custom scheme URL with host and path")
    func parsesCustomSchemeURLWithHostAndPath() {
        // Given
        let url = URL(string: "myapp://home/detail/home-001?query=swift%20ui")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(
            request == DeepLinkRequest(
                path: ["home", "detail", "home-001"],
                data: ["query": "swift ui"]
            )
        )
    }

    @Test("parses universal link URL path without host segment")
    func parsesUniversalLinkURLPathWithoutHostSegment() {
        // Given
        let url = URL(string: "https://example.com/search/results?query=swift")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(
            request == DeepLinkRequest(
                path: ["search", "results"],
                data: ["query": "swift"]
            )
        )
    }

    @Test("keeps last repeated query item value")
    func keepsLastRepeatedQueryItemValue() {
        // Given
        let url = URL(string: "myapp://search/results?query=swift&query=swiftui")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.data["query"] == "swiftui")
    }

    @Test("normalizes query item keys to lowercase")
    func normalizesQueryItemKeysToLowercase() {
        // Given
        let url = URL(string: "myapp://search/results?Query=swiftui")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.data["query"] == "swiftui")
    }

    @Test("keeps last value for mixed-case duplicate query keys")
    func keepsLastValueForMixedCaseDuplicateQueryKeys() {
        // Given
        let url = URL(string: "myapp://search/results?Query=swift&query=swiftui")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.data["query"] == "swiftui")
    }

    @Test("ignores query items without value")
    func ignoresQueryItemsWithoutValue() {
        // Given
        let url = URL(string: "myapp://search/results?query")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.data.isEmpty == true)
    }

    @Test("ignores empty path segments")
    func ignoresEmptyPathSegments() {
        // Given
        let url = URL(string: "myapp://home//detail///home-001")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.path == ["home", "detail", "home-001"])
    }

    @Test("decodes percent-encoded path and query values")
    func decodesPercentEncodedPathAndQueryValues() {
        // Given
        let url = URL(string: "myapp://search/results/swift%20ui?query=deep%20link")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.path == ["search", "results", "swift ui"])
        #expect(request?.data == ["query": "deep link"])
    }

    @Test("parses custom scheme URL with path-only format")
    func parsesCustomSchemeURLWithPathOnlyFormat() {
        // Given
        let url = URL(string: "myapp:/detail/123")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.path == ["detail", "123"])
    }

    @Test("ignores URL fragment while parsing")
    func ignoresURLFragmentWhileParsing() {
        // Given
        let url = URL(string: "myapp://home/detail/123?query=swift#section")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.path == ["home", "detail", "123"])
        #expect(request?.data["query"] == "swift")
    }

    @Test("provides root and childPath helpers")
    func providesRootAndChildPathHelpers() {
        // Given
        let url = URL(string: "myapp://home/detail/123")!

        // When
        let request = DeepLinkParser.parse(url: url)

        // Then
        #expect(request?.root == "home")
        #expect(request?.childPath == ["detail", "123"])
    }

    @Test("returns nil for URL without routable path")
    func returnsNilForURLWithoutRoutablePath() {
        // Given
        let customSchemeURL = URL(string: "myapp://")!
        let universalLinkURL = URL(string: "https://example.com")!

        // When
        let customRequest = DeepLinkParser.parse(url: customSchemeURL)
        let universalRequest = DeepLinkParser.parse(url: universalLinkURL)

        // Then
        #expect(customRequest == nil)
        #expect(universalRequest == nil)
    }

    @Test("options can disable host inclusion for custom schemes")
    func optionsCanDisableHostInclusionForCustomSchemes() {
        // Given
        let url = URL(string: "myapp://home/detail/123")!
        let options = DeepLinkParser.Options(includeHostForCustomSchemes: false)

        // When
        let request = DeepLinkParser.parse(url: url, options: options)

        // Then
        #expect(request?.path == ["detail", "123"])
    }

    @Test("options can lowercase path segments")
    func optionsCanLowercasePathSegments() {
        // Given
        let url = URL(string: "myapp://Home/Detail/ABC")!
        let options = DeepLinkParser.Options(normalizePathToLowercase: true)

        // When
        let request = DeepLinkParser.parse(url: url, options: options)

        // Then
        #expect(request?.path == ["home", "detail", "abc"])
    }

    @Test("options can preserve query key casing")
    func optionsCanPreserveQueryKeyCasing() {
        // Given
        let url = URL(string: "myapp://search/results?Query=swiftui")!
        let options = DeepLinkParser.Options(normalizeQueryKeysToLowercase: false)

        // When
        let request = DeepLinkParser.parse(url: url, options: options)

        // Then
        #expect(request?.data["Query"] == "swiftui")
        #expect(request?.data["query"] == nil)
    }

    @Test("options can keep first repeated query value")
    func optionsCanKeepFirstRepeatedQueryValue() {
        // Given
        let url = URL(string: "myapp://search/results?query=swift&query=swiftui")!
        let options = DeepLinkParser.Options(queryDuplicatePolicy: .firstWins)

        // When
        let request = DeepLinkParser.parse(url: url, options: options)

        // Then
        #expect(request?.data["query"] == "swift")
    }
}

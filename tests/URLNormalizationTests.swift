import Foundation
import Testing
@testable import Copycola

struct URLNormalizationTests {
    @Test func addsHTTPSWhenTheSchemeIsMissing() {
        #expect(normalizedURL("example.com/path")?.absoluteString == "https://example.com/path")
    }

    @Test func preservesSupportedSchemes() {
        #expect(normalizedURL("http://example.com")?.scheme == "http")
        #expect(normalizedURL("HTTPS://example.com")?.scheme == "https")
    }

    @Test func rejectsEmptyUnsupportedAndHostlessValues() {
        #expect(normalizedURL("   ") == nil)
        #expect(normalizedURL("file:///tmp/image.png") == nil)
        #expect(normalizedURL("https://") == nil)
    }
}

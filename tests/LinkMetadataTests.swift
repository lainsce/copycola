import Testing
@testable import Copycola

struct LinkMetadataTests {
    @Test
    func extractsThemeColorRegardlessOfAttributeOrder() {
        let html = #"""
        <head>
          <meta content="#3A7BD5" name="theme-color">
          <meta name="description" content="A &amp; B">
        </head>
        """#

        let metadata = parseHTMLMetadata(html)

        #expect(metadata.themeColorHex == "3A7BD5")
        #expect(metadata.description == "A & B")
    }

    @Test
    func normalizesShortHexAndRgbThemeColors() {
        #expect(parseHTMLMetadata(##"<meta name="theme-color" content="#abc">"##).themeColorHex == "AABBCC")
        #expect(parseHTMLMetadata(##"<meta name="theme-color" content="rgb(12, 34, 56)">"##).themeColorHex == "0C2238")
    }

    @Test
    func ignoresUnsupportedOrInvalidThemeColors() {
        #expect(parseHTMLMetadata(##"<meta name="theme-color" content="papayawhip">"##).themeColorHex == nil)
        #expect(parseHTMLMetadata(##"<meta name="theme-color" content="#12">"##).themeColorHex == nil)
        #expect(parseHTMLMetadata(##"<meta name="theme-color" content="#GGGGGG">"##).themeColorHex == nil)
    }
}

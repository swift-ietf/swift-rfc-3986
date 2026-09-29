import Testing

@testable import RFC_3986

@Suite
struct `Percent-encoding bytes` {

    @Test
    func `Encoding uses uppercase hex`() {
        let encoded = RFC_3986.percentEncode(Array("hello world".utf8))
        let text = String(decoding: encoded, as: UTF8.self)

        #expect(text.contains("%20"))
        #expect(!text.contains("%2a"))
    }

    @Test
    func `Encoding structural characters`() {
        let encoded = RFC_3986.percentEncode(Array("hello?world#test".utf8))
        let text = String(decoding: encoded, as: UTF8.self)

        #expect(text.contains("%3F"))
        #expect(text.contains("%23"))
    }

    @Test
    func `Unreserved characters are left alone`() {
        let unreserved = "hello-world_123.test~abc"
        let encoded = RFC_3986.percentEncode(Array(unreserved.utf8))

        #expect(String(decoding: encoded, as: UTF8.self) == unreserved)
    }

    @Test
    func `Encoding into a component character set`() {
        let encoded = RFC_3986.percentEncode(Array("path:with@special".utf8), allowing: .pathSegment)

        #expect(String(decoding: encoded, as: UTF8.self) == "path:with@special")
    }

    @Test
    func `Encoding an empty sequence`() {
        #expect(RFC_3986.percentEncode(Array("".utf8)).isEmpty)
    }

    @Test
    func `Encoding into an existing buffer`() {
        var buffer = Array("prefix=".utf8)
        RFC_3986.percentEncode(Array("a b".utf8), into: &buffer)

        #expect(String(decoding: buffer, as: UTF8.self) == "prefix=a%20b")
    }

    @Test(arguments: [
        "hello world",
        "test?query=value",
        "path/to/resource",
        "special!@#$%^&*()",
        "🌍🚀✨",
        "café",
        "寿司",
        "a\u{0301}",
        "   ",
    ])
    func `Encode-decode round trip`(input: String) {
        let encoded = RFC_3986.percentEncode(Array(input.utf8))
        let decoded = RFC_3986.percentDecode(encoded)

        #expect(String(decoding: decoded, as: UTF8.self) == input)
    }
}

@Suite
struct `Percent-decoding bytes` {

    @Test
    func `Decoding a percent-encoded sequence`() {
        let decoded = RFC_3986.percentDecode(Array("hello%20world%3Ftest".utf8))

        #expect(String(decoding: decoded, as: UTF8.self) == "hello world?test")
    }

    @Test
    func `Decoding multi-byte UTF-8`() {
        let decoded = RFC_3986.percentDecode(Array("caf%C3%A9".utf8))

        #expect(String(decoding: decoded, as: UTF8.self) == "café")
    }

    @Test
    func `Decoding an empty sequence`() {
        #expect(RFC_3986.percentDecode(Array("".utf8)).isEmpty)
    }

    @Test(arguments: [
        ("hello%2", "hello%2"),
        ("hello%G0", "hello%G0"),
        ("test%", "test%"),
        ("%ZZ", "%ZZ"),
    ])
    func `Invalid percent-encoding decodes to itself`(input: String, expected: String) {
        let decoded = RFC_3986.percentDecode(Array(input.utf8))

        #expect(String(decoding: decoded, as: UTF8.self) == expected)
    }

    @Test
    func `Mixed encoded and unencoded bytes`() {
        let decoded = RFC_3986.percentDecode(Array("hello world%20test".utf8))

        #expect(String(decoding: decoded, as: UTF8.self) == "hello world test")
    }

    @Test
    func `Consecutive percent signs`() {
        let decoded = RFC_3986.percentDecode(Array("test%25%25".utf8))

        #expect(String(decoding: decoded, as: UTF8.self) == "test%%")
    }
}

@Suite
struct `Normalizing percent-encoding` {

    @Test
    func `Hex digits are uppercased`() {
        #expect(RFC_3986.normalizePercentEncoding("hello%2fworld") == "hello%2Fworld")
    }

    @Test
    func `Encoded unreserved characters are decoded`() {
        #expect(RFC_3986.normalizePercentEncoding("hello%2Dworld") == "hello-world")
    }
}

import Testing

@testable import RFC_3986

@Suite
struct `RFC_3986 percentEncode()` {

    @Test
    func `Encode with UPPERCASE hex`() {
        let input = "hello world"
        let encoded = RFC_3986.percentEncode(input)

        #expect(encoded.contains("%20"))
        #expect(!encoded.contains("%2a"))
    }

    @Test
    func `Encode special characters`() {
        let input = "hello?world#test"
        let encoded = RFC_3986.percentEncode(input)
        #expect(encoded.contains("%3F"))
        #expect(encoded.contains("%23"))
    }

    @Test
    func `Don't encode unreserved characters`() {
        let input = "hello-world_123.test~abc"
        let encoded = RFC_3986.percentEncode(input)
        #expect(encoded == input)
    }

    @Test
    func `Encode emoji`() {
        let input = "hello 🌍 world"
        let encoded = RFC_3986.percentEncode(input)

        #expect(encoded.contains("%"))
        #expect(!encoded.contains("🌍"))

        let decoded = RFC_3986.percentDecode(encoded)
        #expect(decoded == input)
    }

    @Test
    func `Encode non-ASCII characters`() {
        let input = "café"
        let encoded = RFC_3986.percentEncode(input)

        #expect(encoded.contains("%"))
        #expect(encoded.contains("caf"))

        let decoded = RFC_3986.percentDecode(encoded)
        #expect(decoded == input)
    }

    @Test
    func `Encode Japanese characters`() {
        let input = "寿司"
        let encoded = RFC_3986.percentEncode(input)

        #expect(encoded.allSatisfy { $0 == "%" || $0.isASCII })

        let decoded = RFC_3986.percentDecode(encoded)
        #expect(decoded == input)
    }

    @Test
    func `Multi-byte UTF-8 sequences`() {
        let input = "a\u{0301}"
        let encoded = RFC_3986.percentEncode(input)
        let decoded = RFC_3986.percentDecode(encoded)

        #expect(decoded == input)
    }

    @Test
    func `Empty string`() {
        let encoded = RFC_3986.percentEncode("")
        #expect(encoded.isEmpty)
    }

    @Test
    func `String that is 100% percent-encoded`() {
        let input = "   "
        let encoded = RFC_3986.percentEncode(input)

        #expect(encoded == "%20%20%20")

        let decoded = RFC_3986.percentDecode(encoded)
        #expect(decoded == input)
    }

    @Test(arguments: [
        "hello world",
        "test?query=value",
        "path/to/resource",
        "special!@#$%^&*()",
        "🌍🚀✨",
    ])
    func `Encode-decode round trip`(input: String) {
        let encoded = RFC_3986.percentEncode(input)
        let decoded = RFC_3986.percentDecode(encoded)
        #expect(decoded == input)
    }
}

@Suite
struct `RFC_3986 percentDecode()` {

    @Test
    func `Decode percent-encoded string`() {
        let encoded = "hello%20world%3Ftest"
        let decoded = RFC_3986.percentDecode(encoded)
        #expect(decoded == "hello world?test")
    }

    @Test
    func `Empty string`() {
        let decoded = RFC_3986.percentDecode("")
        #expect(decoded.isEmpty)
    }

    @Test(arguments: [
        ("hello%2", "hello%2"),
        ("hello%G0", "hello%G0"),
        ("test%", "test%"),
        ("%ZZ", "%ZZ"),
    ])
    func `Invalid percent-encoding returns original`(input: String, expected: String) {
        let decoded = RFC_3986.percentDecode(input)
        #expect(decoded == expected)
    }

    @Test
    func `Mixed encoded and unencoded`() {
        let input = "hello world%20test"
        let decoded = RFC_3986.percentDecode(input)

        #expect(decoded == "hello world test")
    }

    @Test
    func `Consecutive percent signs`() {
        let input = "test%25%25"
        let decoded = RFC_3986.percentDecode(input)

        #expect(decoded == "test%%")
    }
}

@Suite
struct `RFC_3986 normalizePercentEncoding()` {

    @Test
    func `Normalize percent-encoding - uppercase hex`() {
        let input = "hello%2fworld"
        let normalized = RFC_3986.normalizePercentEncoding(input)
        #expect(normalized == "hello%2Fworld")
    }

    @Test
    func `Normalize percent-encoding - decode unreserved`() {
        let input = "hello%2Dworld"
        let normalized = RFC_3986.normalizePercentEncoding(input)
        #expect(normalized == "hello-world")
    }

    @Test
    func `Already percent-encoded unreserved characters`() {
        let input = "hello%2Dworld"
        let normalized = RFC_3986.normalizePercentEncoding(input)

        #expect(normalized == "hello-world")
    }
}

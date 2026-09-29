import Testing

@testable import RFC_3986

@Suite
struct `README` {

    @Test
    func `Reading the components of a URI`() throws {
        let uri = try RFC_3986.URI(
            "https://user@example.com:8080/path/to/thing?key=value#section"
        )

        #expect(uri.scheme?.value == "https")
        #expect(uri.host == .registeredName("example.com"))
        #expect(uri.port == 8080)
        #expect(uri.path?.description == "/path/to/thing")
        #expect(uri.query?.description == "key=value")
        #expect(uri.fragment?.value == "section")
    }

    @Test
    func `Normalizing a URI`() throws {
        let uri = try RFC_3986.URI("HTTPS://EXAMPLE.COM:443/path")

        #expect(uri.normalized().value == "https://example.com/path")
    }

    @Test
    func `Resolving a relative reference`() throws {
        let base = try RFC_3986.URI("http://example.com/path/to/resource")

        #expect(try base.resolve("../other").value == "http://example.com/path/other")
    }

    @Test
    func `Percent-encoding and decoding bytes`() {
        let encoded = RFC_3986.percentEncode(Array("hello world?".utf8))
        let decoded = RFC_3986.percentDecode(Array("caf%C3%A9".utf8))

        #expect(String(decoding: encoded, as: UTF8.self) == "hello%20world%3F")
        #expect(String(decoding: decoded, as: UTF8.self) == "café")
    }

    @Test
    func `A URI is ASCII only`() {
        #expect(RFC_3986.isValidURI("https://example.com/%E5%AF%BF%E5%8F%B8"))
        #expect(!RFC_3986.isValidURI("https://example.com/寿司"))
    }
}

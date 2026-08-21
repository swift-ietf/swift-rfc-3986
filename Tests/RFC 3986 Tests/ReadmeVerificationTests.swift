import Testing

@testable import RFC_3986

@Suite
struct `README Verification` {

    @Test
    func `Creating URIs - from string literal`() throws {

        let uri = try RFC_3986.URI("https://example.com/path")

        #expect(uri.value == "https://example.com/path")
    }

    @Test
    func `Creating URIs - with validation`() throws {

        let string = "https://example.com/path"
        let validatedURI = try RFC_3986.URI(string)

        #expect(validatedURI.value == "https://example.com/path")
    }

    @Test
    func `Validation - validate URI string`() {

        let isValid = RFC_3986.isValidURI("https://example.com")

        #expect(isValid == true)
    }

    @Test
    func `Validation - validate HTTP specifically`() {

        let isValid = RFC_3986.isValidHTTP("https://example.com")

        #expect(isValid == true)
    }

    @Test
    func `Normalization example`() throws {

        let string = "HTTPS://EXAMPLE.COM:443/path"
        let uri = try RFC_3986.URI(string)
        let normalized = uri.normalized()

        #expect(normalized.value == "https://example.com/path")
    }

    @Test
    func `RFC 3986 Compliance - supports relative references`() {

        let absoluteURI = RFC_3986.isValidURI("https://example.com")
        let relativeRef = RFC_3986.isValidURI("/path/to/resource")
        let queryRef = RFC_3986.isValidURI("?query=value")
        let fragmentRef = RFC_3986.isValidURI("#fragment")

        #expect(absoluteURI == true)
        #expect(relativeRef == true)
        #expect(queryRef == true)
        #expect(fragmentRef == true)
    }

    @Test
    func `RFC 3986 Compliance - ASCII only`() {

        let asciiURI = RFC_3986.isValidURI("https://example.com/path")
        let unicodeURI = RFC_3986.isValidURI("https://example.com/寿司")

        #expect(asciiURI == true)
        #expect(unicodeURI == false)
    }

    @Test
    func `RFC 3986 Compliance - percent-encoded URIs`() throws {

        let string = "https://example.com/%E5%AF%BF%E5%8F%B8"
        let uri = try RFC_3986.URI(string)

        #expect(uri.value.contains("%E5%AF%BF%E5%8F%B8"))
    }

    @Test
    func `Component parsing - scheme`() throws {

        let string = "https://example.com"
        let uri = try RFC_3986.URI(string)

        #expect(uri.scheme?.value == "https")
    }

    @Test
    func `Component parsing - host`() throws {

        let string = "https://example.com/path"
        let uri = try RFC_3986.URI(string)

        #expect(uri.host?.rawValue == "example.com")
    }

    @Test
    func `Component parsing - port`() throws {

        let string = "https://example.com:8080"
        let uri = try RFC_3986.URI(string)

        #expect(uri.port == 8080)
    }

    @Test
    func `Component parsing - path`() throws {

        let string = "https://example.com/path/to/resource"
        let uri = try RFC_3986.URI(string)

        #expect(uri.path?.description == "/path/to/resource")
    }

    @Test
    func `Component parsing - query`() throws {

        let string = "https://example.com?key=value"
        let uri = try RFC_3986.URI(string)

        #expect(uri.query?.description == "key=value")
    }

    @Test
    func `Component parsing - fragment`() throws {

        let string = "https://example.com#section"
        let uri = try RFC_3986.URI(string)

        #expect(uri.fragment?.value == "section")
    }
}

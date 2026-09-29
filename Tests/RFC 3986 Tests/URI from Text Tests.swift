import Testing

@testable import RFC_3986

@Suite
struct `URI built from text` {

    @Test(arguments: [
        ("#fragment", "fragment"),
        ("#results", "results"),
        ("#", ""),
    ])
    func `Fragment-only URI`(input: String, expectedFragment: String) throws {
        let uri = try RFC_3986.URI(input)
        #expect(uri.fragment?.value == expectedFragment)
        #expect(uri.scheme == nil)
        #expect(uri.host == nil)
    }

    @Test(arguments: [
        ("?query=value", "query=value"),
        ("?key=value&foo=bar", "key=value&foo=bar"),
        ("?", ""),
    ])
    func `Query-only URI`(input: String, expectedQuery: String) throws {
        let uri = try RFC_3986.URI(input)
        #expect(uri.query?.description == expectedQuery)
        #expect(uri.scheme == nil)
        #expect(uri.host == nil)
    }

    @Test(arguments: [
        ("https://user:pass@example.com", "user", "pass" as String?, "example.com"),
        ("http://admin:secret@localhost", "admin", "secret" as String?, "localhost"),
        ("ftp://john@example.com", "john", nil as String?, "example.com"),
    ])
    func `URI with userinfo`(
        input: String,
        expectedUser: String,
        expectedPassword: String?,
        expectedHost: String
    ) throws {
        let uri = try RFC_3986.URI(input)
        #expect(uri.userinfo?.user == expectedUser)
        #expect(uri.userinfo?.password == expectedPassword)
        #expect(uri.host.flatMap(\.registeredNameValue) == expectedHost)
    }

    @Test
    func `URI with all components`() throws {
        let uri = try RFC_3986.URI(
            "https://user:pass@example.com:8080/path?query=value#fragment"
        )

        #expect(uri.scheme?.value == "https")
        #expect(uri.userinfo?.user == "user")
        #expect(uri.userinfo?.password == "pass")
        #expect(uri.host == .registeredName("example.com"))
        #expect(uri.port == 8080)
        #expect(uri.path?.description == "/path")
        #expect(uri.query?.description == "query=value")
        #expect(uri.fragment?.value == "fragment")
    }

    @Test(arguments: [
        "not a valid uri 😀",
        "https://例え.jp",
        "http://host with spaces.com",
    ])
    func `Invalid URI text throws`(input: String) {
        #expect(throws: RFC_3986.Error.self) {
            try RFC_3986.URI(input)
        }
    }

    @Test
    func `Building the same URI twice yields the same value`() throws {
        let string = "https://example.com"
        let first = try RFC_3986.URI(string)
        let second = try RFC_3986.URI(string)

        #expect(first.value == second.value)
    }

    @Test
    func `Normalizing percent-encoding on a URI`() throws {
        let uri = try RFC_3986.URI("https://example.com/hello%2dworld")

        #expect(uri.normalizePercentEncoding().value == "https://example.com/hello-world")
        #expect(uri.isHTTP == true)
        #expect(uri.isSecure == true)
    }
}

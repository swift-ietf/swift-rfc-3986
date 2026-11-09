import Testing

@testable import RFC_3986

enum `URI Appending and Validation Tests` {}

extension `URI Appending and Validation Tests` {
    @Suite
    struct `Appending to a URI` {

        @Test
        func `Appending a path component percent-encodes structural characters`() throws {
            let base = try RFC_3986.URI("https://example.com/api")
            let appended = base.appendingPathComponent("../../etc/passwd?x=1#y")

            #expect(appended.value == "https://example.com/api/..%2F..%2Fetc%2Fpasswd%3Fx=1%23y")
            #expect(appended.path?.description == "/api/..%2F..%2Fetc%2Fpasswd%3Fx=1%23y")
            #expect(appended.query == nil)
            #expect(appended.fragment == nil)
        }

        @Test
        func `Appending a query item percent-encodes structural characters in the value`() throws {
            let base = try RFC_3986.URI("https://example.com/path")
            let appended = base.appendingQueryItem(name: "a", value: "1&admin=true#frag")

            #expect(appended.query?.description == "a=1%26admin%3Dtrue%23frag")
            #expect(appended.fragment == nil)
        }

        @Test
        func `Appending a query item percent-encodes structural characters in the name`() throws {
            let base = try RFC_3986.URI("https://example.com/path")
            let appended = base.appendingQueryItem(name: "a&injected=1", value: "x")

            #expect(appended.query?.description == "a%26injected%3D1=x")
        }
    }
}

extension `URI Appending and Validation Tests` {
    @Suite
    struct `Validating URI text` {

        @Test
        func `Malformed percent-encoding is not a valid URI`() {
            #expect(!RFC_3986.isValidURI("http://example.com/100%offsale"))
        }

        @Test
        func `A colon folded into the host by an unparseable port is not a valid URI`() {
            #expect(!RFC_3986.isValidURI("http://example.com:notaport/path"))
        }

        @Test
        func `Construction throws for the same grammar violations validation rejects`() {
            #expect(throws: RFC_3986.Error.self) {
                try RFC_3986.URI("http://example.com/100%offsale")
            }
            #expect(throws: RFC_3986.Error.self) {
                try RFC_3986.URI("http://example.com:notaport/path")
            }
        }
    }
}

extension `URI Appending and Validation Tests` {
    @Suite
    struct `Rebuilding a URI keeps its userinfo` {

        @Test
        func `Normalizing keeps the userinfo`() throws {
            let uri = try RFC_3986.URI("HTTPS://user:pw@Example.COM:443/a/./b")
            #expect(uri.normalized().value == "https://user:pw@example.com/a/b")
        }

        @Test
        func `Appending a path component keeps the userinfo`() throws {
            let uri = try RFC_3986.URI("https://user@example.com:8443/api")
            #expect(uri.appendingPathComponent("v1").value == "https://user@example.com:8443/api/v1")
        }

        @Test
        func `Appending a query item keeps the userinfo`() throws {
            let uri = try RFC_3986.URI("https://user@example.com/path")
            #expect(uri.appendingQueryItem(name: "a", value: "1").value == "https://user@example.com/path?a=1")
        }

        @Test
        func `Setting a fragment keeps the userinfo`() throws {
            let uri = try RFC_3986.URI("https://user@example.com/path")
            let fragment = try RFC_3986.URI.Fragment("top")
            #expect(uri.settingFragment(fragment).value == "https://user@example.com/path#top")
        }

        @Test
        func `Resolving a network-path reference keeps the reference's userinfo`() throws {
            let base = try RFC_3986.URI("https://example.com/a")
            #expect(try base.resolve("//user@other.example:8080/b").value == "https://user@other.example:8080/b")
        }
    }
}

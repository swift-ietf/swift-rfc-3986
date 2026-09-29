import Testing

@testable import RFC_3986

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

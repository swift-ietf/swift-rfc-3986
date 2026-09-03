import Byte
import Byte_Standard_Library_Integration
import Cursor_Standard_Library_Integration
import Testing

@testable import RFC_3986

@Suite
struct `Parse Tests` {
    @Suite struct `Scheme Tests` {}
    @Suite struct `Userinfo Tests` {}
    @Suite struct `Host Tests` {}
    @Suite struct `Port Tests` {}
    @Suite struct `Path Tests` {}
    @Suite struct `Query Tests` {}
    @Suite struct `Fragment Tests` {}
    @Suite struct `Authority Tests` {}
    @Suite struct `Percent Encoded Tests` {}
}

extension `Parse Tests` {

    static func text(_ bytes: [Byte]) -> String {
        String(decoding: bytes.map(\.bitPattern), as: UTF8.self)
    }
}

extension `Parse Tests`.`Scheme Tests` {

    @Test
    func `reads a scheme and stops at the colon`() throws {
        var input = [Byte](utf8: "https://example.com")[...]

        let scheme = try RFC_3986.URI.Scheme.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(scheme) == "https")
        #expect(input.first == Byte(bitPattern: 0x3A))
    }

    @Test
    func `accepts digits, plus, minus and dot after the first letter`() throws {
        var input = [Byte](utf8: "a1+b-c.d:rest")[...]

        let scheme = try RFC_3986.URI.Scheme.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(scheme) == "a1+b-c.d")
    }

    @Test
    func `rejects a scheme that does not start with a letter`() {
        var input = [Byte](utf8: "1http:")[...]

        #expect(throws: RFC_3986.URI.Scheme.ParseFailure.expectedAlpha) {
            try RFC_3986.URI.Scheme.Parse<ArraySlice<Byte>>().parse(&input)
        }
        #expect(input.count == 6)
    }

    @Test
    func `rejects empty input`() {
        var input = [Byte](utf8: "")[...]

        #expect(throws: RFC_3986.URI.Scheme.ParseFailure.expectedAlpha) {
            try RFC_3986.URI.Scheme.Parse<ArraySlice<Byte>>().parse(&input)
        }
    }
}

extension `Parse Tests`.`Userinfo Tests` {

    @Test
    func `reads userinfo characters and stops at the at sign`() {
        var input = [Byte](utf8: "user:pass@host")[...]

        let userinfo = RFC_3986.URI.Userinfo.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(userinfo) == "user:pass")
        #expect(input.first == Byte(bitPattern: 0x40))
    }

    @Test
    func `returns empty when the first byte is not allowed`() {
        var input = [Byte](utf8: "@host")[...]

        let userinfo = RFC_3986.URI.Userinfo.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(userinfo.isEmpty)
        #expect(input.count == 5)
    }
}

extension `Parse Tests`.`Host Tests` {

    @Test
    func `reads a registered name`() throws {
        var input = [Byte](utf8: "example.com:8080")[...]

        let host = try RFC_3986.URI.Host.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(host) == "example.com")
        #expect(input.first == Byte(bitPattern: 0x3A))
    }

    @Test
    func `reads a bracketed IP literal including the brackets`() throws {
        var input = [Byte](utf8: "[::1]:443")[...]

        let host = try RFC_3986.URI.Host.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(host) == "[::1]")
        #expect(input.first == Byte(bitPattern: 0x3A))
    }

    @Test
    func `rejects an unterminated IP literal and restores the cursor`() {
        var input = [Byte](utf8: "[::1")[...]

        #expect(throws: RFC_3986.URI.Host.ParseFailure.unterminatedIPLiteral) {
            try RFC_3986.URI.Host.Parse<ArraySlice<Byte>>().parse(&input)
        }
        #expect(input.count == 4)
    }

    @Test
    func `returns empty on empty input`() throws {
        var input = [Byte](utf8: "")[...]

        let host = try RFC_3986.URI.Host.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(host.isEmpty)
    }
}

extension `Parse Tests`.`Port Tests` {

    @Test
    func `reads a decimal port`() throws {
        var input = [Byte](utf8: "8080/path")[...]

        let port = try RFC_3986.URI.Port.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(port == 8080)
        #expect(input.first == Byte(bitPattern: 0x2F))
    }

    @Test
    func `rejects a non-digit`() {
        var input = [Byte](utf8: "http")[...]

        #expect(throws: RFC_3986.URI.Port.ParseFailure.expectedDigit) {
            try RFC_3986.URI.Port.Parse<ArraySlice<Byte>>().parse(&input)
        }
    }

    @Test
    func `rejects a port beyond sixteen bits`() {
        var input = [Byte](utf8: "65536")[...]

        #expect(throws: RFC_3986.URI.Port.ParseFailure.overflow) {
            try RFC_3986.URI.Port.Parse<ArraySlice<Byte>>().parse(&input)
        }
    }
}

extension `Parse Tests`.`Path Tests` {

    @Test
    func `reads path characters including slashes`() {
        var input = [Byte](utf8: "/a/b/c?query")[...]

        let path = RFC_3986.URI.Path.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(path) == "/a/b/c")
        #expect(input.first == Byte(bitPattern: 0x3F))
    }
}

extension `Parse Tests`.`Query Tests` {

    @Test
    func `reads query characters and stops at the hash`() {
        var input = [Byte](utf8: "a=1&b=2#fragment")[...]

        let query = RFC_3986.URI.Query.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(query) == "a=1&b=2")
        #expect(input.first == Byte(bitPattern: 0x23))
    }
}

extension `Parse Tests`.`Fragment Tests` {

    @Test
    func `reads fragment characters`() {
        var input = [Byte](utf8: "section-1 trailing")[...]

        let fragment = RFC_3986.URI.Fragment.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(fragment) == "section-1")
        #expect(input.first == Byte(bitPattern: 0x20))
    }
}

extension `Parse Tests`.`Authority Tests` {

    @Test
    func `reads userinfo, host and port`() throws {
        var input = [Byte](utf8: "user:pass@example.com:8080/path")[...]

        let authority = try RFC_3986.URI.Authority.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(authority.userinfo.map(`Parse Tests`.text) == "user:pass")
        #expect(`Parse Tests`.text(authority.host) == "example.com")
        #expect(authority.port == 8080)
        #expect(input.first == Byte(bitPattern: 0x2F))
    }

    @Test
    func `reads a bare host`() throws {
        var input = [Byte](utf8: "example.com")[...]

        let authority = try RFC_3986.URI.Authority.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(authority.userinfo == nil)
        #expect(`Parse Tests`.text(authority.host) == "example.com")
        #expect(authority.port == nil)
    }

    @Test
    func `reads a bracketed IP literal host with a port`() throws {
        var input = [Byte](utf8: "[::1]:443")[...]

        let authority = try RFC_3986.URI.Authority.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(`Parse Tests`.text(authority.host) == "[::1]")
        #expect(authority.port == 443)
    }

    @Test
    func `rejects an unterminated IP literal`() {
        var input = [Byte](utf8: "[::1")[...]

        #expect(throws: RFC_3986.URI.Authority.ParseFailure.unterminatedIPLiteral) {
            try RFC_3986.URI.Authority.Parse<ArraySlice<Byte>>().parse(&input)
        }
    }

    @Test
    func `rejects a port beyond sixteen bits`() {
        var input = [Byte](utf8: "example.com:99999")[...]

        #expect(throws: RFC_3986.URI.Authority.ParseFailure.portOverflow) {
            try RFC_3986.URI.Authority.Parse<ArraySlice<Byte>>().parse(&input)
        }
    }
}

extension `Parse Tests`.`Percent Encoded Tests` {

    @Test
    func `decodes a percent-encoded triplet`() throws {
        var input = [Byte](utf8: "%2Frest")[...]

        let decoded = try RFC_3986.Parse.PercentEncoded.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(decoded == Byte(bitPattern: 0x2F))
        #expect(input.count == 4)
    }

    @Test
    func `decodes lowercase hexadecimal`() throws {
        var input = [Byte](utf8: "%ff")[...]

        let decoded = try RFC_3986.Parse.PercentEncoded.Parse<ArraySlice<Byte>>().parse(&input)

        #expect(decoded == Byte(bitPattern: 0xFF))
    }

    @Test
    func `rejects input that does not start with a percent`() {
        var input = [Byte](utf8: "2F")[...]

        #expect(throws: RFC_3986.Parse.PercentEncoded.Failure.expectedPercent) {
            try RFC_3986.Parse.PercentEncoded.Parse<ArraySlice<Byte>>().parse(&input)
        }
        #expect(input.count == 2)
    }

    @Test
    func `rejects a truncated triplet and restores the cursor`() {
        var input = [Byte](utf8: "%2")[...]

        #expect(throws: RFC_3986.Parse.PercentEncoded.Failure.expectedHexDigit) {
            try RFC_3986.Parse.PercentEncoded.Parse<ArraySlice<Byte>>().parse(&input)
        }
        #expect(input.count == 2)
    }

    @Test
    func `rejects a non-hexadecimal digit`() {
        var input = [Byte](utf8: "%2G")[...]

        #expect(throws: RFC_3986.Parse.PercentEncoded.Failure.expectedHexDigit) {
            try RFC_3986.Parse.PercentEncoded.Parse<ArraySlice<Byte>>().parse(&input)
        }
    }
}

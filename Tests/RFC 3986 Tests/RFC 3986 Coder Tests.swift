#if Coder
    import Byte
    import Coder
    import Cursor
    import IPv6_Standard
    import Parser
    import RFC_3986
    import Serializer
    import Testing

extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests` {
        @Suite
        struct `RFC 3986 Coder Tests` {
        }
}

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests` {
        @Suite struct `Scheme Tests` {}

        @Suite struct `Userinfo Tests` {}

        @Suite struct `Host Tests` {}

        @Suite struct `Port Tests` {}

        @Suite struct `Path Tests` {}

        @Suite struct `Query Tests` {}

        @Suite struct `Fragment Tests` {}

        @Suite struct `Authority Tests` {}

        @Suite struct `Percent Encoded Tests` {}

        @Suite struct `URI Tests` {}
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Scheme Tests` {

        @Test
        func `reads a scheme and stops at the colon`() throws {
            var input: ArraySlice<Byte> = "https://example.com"
            #expect(try RFC_3986.URI.Scheme.coder.parse(&input) == .https)
            #expect(input.first == Byte(bitPattern: 0x3A))
        }

        @Test
        func `accepts digits, plus, minus and dot after the first letter`() throws {
            var input: ArraySlice<Byte> = "a1+b-c.d:rest"
            #expect(try RFC_3986.URI.Scheme.coder.parse(&input).rawValue == "a1+b-c.d")
        }

        @Test
        func `rejects a scheme that does not start with a letter and restores the cursor`() {
            var input: ArraySlice<Byte> = "1http:"
            #expect(throws: RFC_3986.URI.Scheme.Error.invalidStart("1", byte: Byte(bitPattern: 0x31))) {
                try RFC_3986.URI.Scheme.coder.parse(&input)
            }
            #expect(input.count == 6)
        }

        @Test
        func `rejects empty input`() {
            var input: ArraySlice<Byte> = ""
            #expect(throws: RFC_3986.URI.Scheme.Error.empty) {
                try RFC_3986.URI.Scheme.coder.parse(&input)
            }
        }

        @Test
        func `round-trips`() throws {
            #expect(try type(of: RFC_3986.URI.Scheme.https).coder.serialize(RFC_3986.URI.Scheme.https) == [Byte](utf8: "https"))
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Userinfo Tests` {

        @Test
        func `reads userinfo characters and stops at the at sign`() throws {
            var input: ArraySlice<Byte> = "user:pass@host"
            #expect(try RFC_3986.URI.Userinfo.coder.parse(&input).rawValue == "user:pass")
            #expect(input.first == Byte(bitPattern: 0x40))
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Host Tests` {

        @Test
        func `reads a registered name`() throws {
            var input: ArraySlice<Byte> = "example.com:8080"
            #expect(try RFC_3986.URI.Host.coder.parse(&input) == .registeredName("example.com"))
            #expect(input.first == Byte(bitPattern: 0x3A))
        }

        @Test
        func `reads a bracketed IP literal`() throws {
            var input: ArraySlice<Byte> = "[::1]/path"
            let host = try RFC_3986.URI.Host.coder.parse(&input)
            #expect(host.ipv6Address == RFC_4291.IPv6.Address.loopback)
            #expect(host.ipv6ScopedAddress?.zone == nil)
            #expect(input.first == Byte(bitPattern: 0x2F))
        }

        @Test
        func `rejects an unterminated IP literal and restores the cursor`() {
            var input: ArraySlice<Byte> = "[::1"
            #expect(throws: RFC_3986.URI.Host.Error.self) {
                try RFC_3986.URI.Host.coder.parse(&input)
            }
            #expect(input.count == 4)
        }

        @Test
        func `rejects an empty host`() {
            var input: ArraySlice<Byte> = "/path"
            #expect(throws: RFC_3986.URI.Host.Error.empty) {
                try RFC_3986.URI.Host.coder.parse(&input)
            }
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Port Tests` {

        @Test
        func `reads a decimal port`() throws {
            var input: ArraySlice<Byte> = "8080/"
            #expect(try RFC_3986.URI.Port.coder.parse(&input).value == 8080)
            #expect(input.first == Byte(bitPattern: 0x2F))
        }

        @Test
        func `rejects a non-digit`() {
            var input: ArraySlice<Byte> = "x"
            #expect(throws: RFC_3986.URI.Port.Error.empty) {
                try RFC_3986.URI.Port.coder.parse(&input)
            }
        }

        @Test
        func `rejects a port beyond sixteen bits`() {
            var input: ArraySlice<Byte> = "70000"
            #expect(throws: RFC_3986.URI.Port.Error.overflow("70000")) {
                try RFC_3986.URI.Port.coder.parse(&input)
            }
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Path Tests` {

        @Test
        func `reads path characters including slashes and stops at the query`() throws {
            var input: ArraySlice<Byte> = "/a/b%20c?x"
            #expect(try RFC_3986.URI.Path.coder.parse(&input).description == "/a/b%20c")
            #expect(input.first == Byte(bitPattern: 0x3F))
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Query Tests` {

        @Test
        func `reads query characters and stops at the hash`() throws {
            var input: ArraySlice<Byte> = "a=1&b=2#frag"
            #expect(try RFC_3986.URI.Query.coder.parse(&input).rawValue == "a=1&b=2")
            #expect(input.first == Byte(bitPattern: 0x23))
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Fragment Tests` {

        @Test
        func `reads fragment characters`() throws {
            var input: ArraySlice<Byte> = "section-1 rest"
            #expect(try RFC_3986.URI.Fragment.coder.parse(&input).rawValue == "section-1")
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Authority Tests` {

        @Test
        func `reads userinfo, host and port`() throws {
            var input: ArraySlice<Byte> = "user@example.com:8080/x"
            let authority = try RFC_3986.URI.Authority.coder.parse(&input)
            #expect(authority.userinfo?.rawValue == "user")
            #expect(authority.host == .registeredName("example.com"))
            #expect(authority.port?.value == 8080)
            #expect(input.first == Byte(bitPattern: 0x2F))
        }

        @Test
        func `reads a bare host`() throws {
            var input: ArraySlice<Byte> = "example.com/x"
            let authority = try RFC_3986.URI.Authority.coder.parse(&input)
            #expect(authority.userinfo == nil)
            #expect(authority.host == .registeredName("example.com"))
            #expect(authority.port == nil)
        }

        @Test
        func `reads a bracketed IP literal host with a port`() throws {
            var input: ArraySlice<Byte> = "[::1]:443"
            let authority = try RFC_3986.URI.Authority.coder.parse(&input)
            #expect(authority.host.ipv6Address == RFC_4291.IPv6.Address.loopback)
            #expect(authority.host.ipv6ScopedAddress?.zone == nil)
            #expect(authority.port?.value == 443)
        }

        @Test
        func `round-trips`() throws {
            var input: ArraySlice<Byte> = "user@example.com:8080"
            let authority = try RFC_3986.URI.Authority.coder.parse(&input)
            #expect(try type(of: authority).coder.serialize(authority) == [Byte](utf8: "user@example.com:8080"))
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Percent Encoded Tests` {

        @Test
        func `decodes a percent-encoded triplet`() throws {
            var input: ArraySlice<Byte> = "%2Fx"
            #expect(try RFC_3986.PercentEncoded.coder.parse(&input) == Byte(bitPattern: 0x2F))
            #expect(input.count == 1)
        }

        @Test
        func `decodes lowercase hexadecimal`() throws {
            var input: ArraySlice<Byte> = "%2f"
            #expect(try RFC_3986.PercentEncoded.coder.parse(&input) == Byte(bitPattern: 0x2F))
        }

        @Test
        func `rejects input that does not start with a percent`() {
            var input: ArraySlice<Byte> = "x"
            #expect(throws: RFC_3986.PercentEncoded.Error.expectedPercent) {
                try RFC_3986.PercentEncoded.coder.parse(&input)
            }
        }

        @Test
        func `rejects a truncated triplet and restores the cursor`() {
            var input: ArraySlice<Byte> = "%2"
            #expect(throws: RFC_3986.PercentEncoded.Error.expectedHexDigit) {
                try RFC_3986.PercentEncoded.coder.parse(&input)
            }
            #expect(input.count == 2)
        }

        @Test
        func `serializes uppercase`() throws {
            var buffer: [Byte] = []
            try RFC_3986.PercentEncoded.coder.serialize(Byte(bitPattern: 0x2F), into: &buffer)
            #expect(buffer == "%2F")
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`URI Tests` {

        @Test
        func `parses an absolute URI with every component`() throws {
            var input: ArraySlice<Byte> = "https://user@example.com:8080/a/b?x=1#f rest"
            let uri = try RFC_3986.URI.coder.parse(&input)
            #expect(uri.value == "https://user@example.com:8080/a/b?x=1#f")
            #expect(uri.scheme == .https)
            #expect(uri.host == .registeredName("example.com"))
            #expect(uri.port?.value == 8080)
            #expect(uri.query?.rawValue == "x=1")
            #expect(uri.fragment?.rawValue == "f")
            #expect(input.first == Byte(bitPattern: 0x20))
        }

        @Test
        func `parses a URI without an authority`() throws {
            var input: ArraySlice<Byte> = "mailto:a@b.example"
            let uri = try RFC_3986.URI.coder.parse(&input)
            #expect(uri.scheme == .mailto)
            #expect(uri.value == "mailto:a@b.example")
        }

        @Test
        func `parses repeated question marks into the query and fragment`() throws {
            var input: ArraySlice<Byte> = "https://example.com/a?b?c#d?e"
            let uri = try RFC_3986.URI.coder.parse(&input)
            #expect(uri.path?.description == "/a")
            #expect(uri.query?.description == "b?c")
            #expect(uri.fragment?.value == "d?e")
            #expect(input.isEmpty)
        }

        @Test
        func `rejects a missing scheme`() {
            var input: ArraySlice<Byte> = "//example.com"
            #expect(throws: RFC_3986.Error.self) {
                try RFC_3986.URI.coder.parse(&input)
            }
            #expect(input.count == 13)
        }

        @Test
        func `round-trips`() throws {
            let uri = try RFC_3986.URI("https://example.com/path?q=1")
            #expect(try type(of: uri).coder.serialize(uri) == [Byte](utf8: "https://example.com/path?q=1"))
        }
    }

    extension `RFC 3986 Coder Tests`.`RFC 3986 Coder Tests`.`Authority Tests` {
        @Test func `a present malformed port is committed`() {
            var input = [Byte](utf8: "example.com:invalid/path")[...]
            #expect(throws: RFC_3986.URI.Authority.Error.self) {
                try RFC_3986.URI.Authority.coder.parse(&input)
            }
            #expect(input.first == Byte(bitPattern: 0x2F))
        }

        @Test func `a missing port remains optional`() throws {
            var input = [Byte](utf8: "example.com?query")[...]
            let authority = try RFC_3986.URI.Authority.coder.parse(&input)
            #expect(authority.port == nil)
            #expect(input.first == Byte(bitPattern: 0x3F))
        }
    }
#endif

#if Coder
    import ASCII
    import Binary
    import Byte
    import Coder
    import RFC_3986
    import Serializer
    import Testing

    @Suite
    struct `Serialization Tests` {

        @Test
        func `a scheme writes its lowercase name`() throws {
            let scheme = try RFC_3986.URI.Scheme("https")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Scheme.serialize(scheme, into: &ascii)
            var wire: [Byte] = []
            RFC_3986.URI.Scheme.serialize(scheme, into: &wire)
            #expect(ascii.map(\.byte) == "https")
            #expect(wire == "https")
            #expect(try type(of: scheme).coder.serialize(scheme) == [Byte](utf8: "https"))
        }

        @Test
        func `a port writes its decimal digits`() throws {
            let port = RFC_3986.URI.Port(8080)
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Port.serialize(port, into: &ascii)
            var wire: [Byte] = []
            RFC_3986.URI.Port.serialize(port, into: &wire)
            #expect(ascii.map(\.byte) == "8080")
            #expect(wire == "8080")
            #expect(try type(of: port).coder.serialize(port) == [Byte](utf8: "8080"))
        }

        @Test
        func `a path writes its segments separated by solidus`() throws {
            let path = try RFC_3986.URI.Path("/a/b/c")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Path.serialize(path, into: &ascii)
            var wire: [Byte] = []
            RFC_3986.URI.Path.serialize(path, into: &wire)
            #expect(ascii.map(\.byte) == "/a/b/c")
            #expect(wire == "/a/b/c")
            #expect(try type(of: path).coder.serialize(path) == [Byte](utf8: "/a/b/c"))
        }

        @Test
        func `a root path writes a single solidus`() throws {
            let path = try RFC_3986.URI.Path("/")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Path.serialize(path, into: &ascii)
            #expect(ascii.map(\.byte) == "/")
            #expect(try type(of: path).coder.serialize(path) == [Byte](utf8: "/"))
        }

        @Test
        func `a query writes its parameters`() throws {
            let query = try RFC_3986.URI.Query("a=1&b=2")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Query.serialize(query, into: &ascii)
            var wire: [Byte] = []
            RFC_3986.URI.Query.serialize(query, into: &wire)
            #expect(ascii.map(\.byte) == "a=1&b=2")
            #expect(wire == "a=1&b=2")
            #expect(try type(of: query).coder.serialize(query) == [Byte](utf8: "a=1&b=2"))
        }

        @Test
        func `a fragment writes its characters`() throws {
            let fragment = try RFC_3986.URI.Fragment("section-1")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Fragment.serialize(fragment, into: &ascii)
            #expect(ascii.map(\.byte) == "section-1")
            #expect(try type(of: fragment).coder.serialize(fragment) == [Byte](utf8: "section-1"))
        }

        @Test
        func `userinfo writes user and password`() throws {
            let userinfo = try RFC_3986.URI.Userinfo("user:pass")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Userinfo.serialize(userinfo, into: &ascii)
            #expect(ascii.map(\.byte) == "user:pass")
            #expect(try type(of: userinfo).coder.serialize(userinfo) == [Byte](utf8: "user:pass"))
        }

        @Test
        func `a registered name host writes its label`() throws {
            let host = try RFC_3986.URI.Host("example.com")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Host.serialize(host, into: &ascii)
            var wire: [Byte] = []
            RFC_3986.URI.Host.serialize(host, into: &wire)
            #expect(ascii.map(\.byte) == "example.com")
            #expect(wire == "example.com")
            #expect(try type(of: host).coder.serialize(host) == [Byte](utf8: "example.com"))
        }

        @Test
        func `an IPv4 host writes dotted decimal`() throws {
            let host = try RFC_3986.URI.Host("192.168.1.1")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Host.serialize(host, into: &ascii)
            #expect(ascii.map(\.byte) == "192.168.1.1")
            #expect(try type(of: host).coder.serialize(host) == [Byte](utf8: "192.168.1.1"))
        }

        @Test
        func `an IPv6 host writes a bracketed literal`() throws {
            let host = try RFC_3986.URI.Host("[::1]")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Host.serialize(host, into: &ascii)
            var wire: [Byte] = []
            RFC_3986.URI.Host.serialize(host, into: &wire)
            #expect(ascii.map(\.byte) == "[::1]")
            #expect(wire == "[::1]")
            #expect(try type(of: host).coder.serialize(host) == [Byte](utf8: "[::1]"))
        }

        @Test
        func `an IPv6 host writes its zone percent-encoded`() throws {
            let host = try RFC_3986.URI.Host("[fe80::1%25eth0]")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Host.serialize(host, into: &ascii)
            #expect(ascii.map(\.byte) == "[fe80::1%25eth0]")
            #expect(try type(of: host).coder.serialize(host) == [Byte](utf8: "[fe80::1%25eth0]"))
        }

        @Test
        func `an IPv6 host refuses a zone the zone type cannot hold`() {
            #expect(throws: RFC_3986.URI.Host.Error.self) {
                try RFC_3986.URI.Host("[fe80::1%25eth%200]")
            }
        }

        @Test
        func `a normalized URI keeps its IPv6 literal as written while its host serializes canonically`() throws {
            let normalized = try RFC_3986.URI("HTTP://[2001:0DB8::1]:80/a/./b").normalized()
            #expect(normalized.value == "http://[2001:0db8::1]/a/b")

            let host = try #require(normalized.host)
            #expect(try type(of: host).coder.serialize(host) == [Byte](utf8: "[2001:db8::1]"))
        }

        @Test
        func `an authority writes userinfo, host and port`() throws {
            let authority = try RFC_3986.URI.Authority("user@example.com:8080")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Authority.serialize(authority, into: &ascii)
            var wire: [Byte] = []
            RFC_3986.URI.Authority.serialize(authority, into: &wire)
            #expect(ascii.map(\.byte) == "user@example.com:8080")
            #expect(wire == "user@example.com:8080")
            #expect(try type(of: authority).coder.serialize(authority) == [Byte](utf8: "user@example.com:8080"))
        }

        @Test
        func `an authority writes a bracketed IPv6 host with its port`() throws {
            let authority = try RFC_3986.URI.Authority("[2001:db8::1]:443")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.Authority.serialize(authority, into: &ascii)
            #expect(ascii.map(\.byte) == "[2001:db8::1]:443")
            #expect(try type(of: authority).coder.serialize(authority) == [Byte](utf8: "[2001:db8::1]:443"))
        }

        @Test
        func `a URI writes every component in order`() throws {
            let uri = try RFC_3986.URI("https://user@example.com:8080/path?query=value#frag")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.serialize(uri, into: &ascii)
            var wire: [Byte] = []
            RFC_3986.URI.serialize(uri, into: &wire)
            #expect(ascii.map(\.byte) == "https://user@example.com:8080/path?query=value#frag")
            #expect(wire == "https://user@example.com:8080/path?query=value#frag")
            #expect(try type(of: uri).coder.serialize(uri) == [Byte](utf8: "https://user@example.com:8080/path?query=value#frag"))
        }

        @Test
        func `a URI writes a bracketed IPv6 authority`() throws {
            let uri = try RFC_3986.URI("http://[2001:db8::1]:443/path")
            var ascii: [ASCII.Code] = []
            RFC_3986.URI.serialize(uri, into: &ascii)
            #expect(ascii.map(\.byte) == "http://[2001:db8::1]:443/path")
            #expect(try type(of: uri).coder.serialize(uri) == [Byte](utf8: "http://[2001:db8::1]:443/path"))
        }
    }
#endif

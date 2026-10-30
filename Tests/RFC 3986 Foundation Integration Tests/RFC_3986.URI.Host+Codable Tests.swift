#if Coder
    import Foundation
    import RFC_3986
    import RFC_3986_Foundation_Integration
    import Testing

    @Suite
    struct `RFC_3986.URI.Host+Codable Tests` {

        @Test
        func `a host codes as its text form`() async throws {
            let host = try RFC_3986.URI.Host("example.com")

            let encoded = try JSONEncoder().encode(host)

            #expect(String(decoding: encoded, as: UTF8.self) == #""example.com""#)
            #expect(try JSONDecoder().decode(RFC_3986.URI.Host.self, from: encoded) == host)
        }

        @Test
        func `an IPv6 host codes as its canonical bracketed literal`() async throws {
            let host = try RFC_3986.URI.Host("[2001:0DB8::1]")

            let encoded = try JSONEncoder().encode(host)

            #expect(String(decoding: encoded, as: UTF8.self) == #""[2001:db8::1]""#)
            #expect(try JSONDecoder().decode(RFC_3986.URI.Host.self, from: encoded) == host)
        }

        @Test
        func `a malformed host fails to decode`() async throws {
            let encoded = Data(#""exa mple.com""#.utf8)

            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(RFC_3986.URI.Host.self, from: encoded)
            }
        }

        @Test
        func `an authority codes as its text form`() async throws {
            let authority = try RFC_3986.URI.Authority("user@example.com:8080")

            let encoded = try JSONEncoder().encode(authority)

            #expect(String(decoding: encoded, as: UTF8.self) == #""user@example.com:8080""#)
            #expect(try JSONDecoder().decode(RFC_3986.URI.Authority.self, from: encoded) == authority)
        }

        @Test
        func `a malformed authority fails to decode`() async throws {
            let encoded = Data(#""example.com:port""#.utf8)

            #expect(throws: DecodingError.self) {
                try JSONDecoder().decode(RFC_3986.URI.Authority.self, from: encoded)
            }
        }
    }
#endif

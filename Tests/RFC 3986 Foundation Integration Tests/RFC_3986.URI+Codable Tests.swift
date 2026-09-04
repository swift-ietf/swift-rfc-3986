import Foundation
import RFC_3986
import RFC_3986_Foundation_Integration
import Testing

@Suite
struct `RFC_3986.URI+Codable Tests` {

    @Test
    func `a uri codes as its text form`() async throws {
        let uri = try RFC_3986.URI("https://example.com/a/b?q=1#top")

        let encoded = try JSONEncoder().encode(uri)

        #expect(String(decoding: encoded, as: UTF8.self) == #""https:\/\/example.com\/a\/b?q=1#top""#)
        #expect(try JSONDecoder().decode(RFC_3986.URI.self, from: encoded) == uri)
    }

    @Test
    func `an authority codes as its text form`() async throws {
        let authority = try RFC_3986.URI.Authority("user@example.com:8080")

        let encoded = try JSONEncoder().encode(authority)

        #expect(String(decoding: encoded, as: UTF8.self) == #""user@example.com:8080""#)
        #expect(try JSONDecoder().decode(RFC_3986.URI.Authority.self, from: encoded) == authority)
    }

    @Test
    func `a fragment codes as its text form`() async throws {
        let fragment = try RFC_3986.URI.Fragment("section-1")

        let encoded = try JSONEncoder().encode(fragment)

        #expect(String(decoding: encoded, as: UTF8.self) == #""section-1""#)
        #expect(try JSONDecoder().decode(RFC_3986.URI.Fragment.self, from: encoded) == fragment)
    }

    @Test
    func `a host codes as its text form`() async throws {
        let host = try RFC_3986.URI.Host("example.com")

        let encoded = try JSONEncoder().encode(host)

        #expect(String(decoding: encoded, as: UTF8.self) == #""example.com""#)
        #expect(try JSONDecoder().decode(RFC_3986.URI.Host.self, from: encoded) == host)
    }

    @Test
    func `a path codes as its text form`() async throws {
        let path = try RFC_3986.URI.Path("/users/42")

        let encoded = try JSONEncoder().encode(path)

        #expect(String(decoding: encoded, as: UTF8.self) == #""\/users\/42""#)
        #expect(try JSONDecoder().decode(RFC_3986.URI.Path.self, from: encoded) == path)
    }

    @Test
    func `a malformed path fails to decode`() async throws {
        let encoded = Data(#""/users/%zz""#.utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(RFC_3986.URI.Path.self, from: encoded)
        }
    }

    @Test
    func `a port codes as its number`() async throws {
        let port = RFC_3986.URI.Port(8080)

        let encoded = try JSONEncoder().encode(port)

        #expect(String(decoding: encoded, as: UTF8.self) == "8080")
        #expect(try JSONDecoder().decode(RFC_3986.URI.Port.self, from: encoded) == port)
    }

    @Test
    func `a query codes as its text form`() async throws {
        let query = try RFC_3986.URI.Query("page=2&sort=name")

        let encoded = try JSONEncoder().encode(query)

        #expect(String(decoding: encoded, as: UTF8.self) == #""page=2&sort=name""#)
        #expect(try JSONDecoder().decode(RFC_3986.URI.Query.self, from: encoded) == query)
    }

    @Test
    func `a scheme codes as its text form`() async throws {
        let scheme = try RFC_3986.URI.Scheme("https")

        let encoded = try JSONEncoder().encode(scheme)

        #expect(String(decoding: encoded, as: UTF8.self) == #""https""#)
        #expect(try JSONDecoder().decode(RFC_3986.URI.Scheme.self, from: encoded) == scheme)
    }

    @Test
    func `a userinfo codes as its text form`() async throws {
        let userinfo = try RFC_3986.URI.Userinfo("alice")

        let encoded = try JSONEncoder().encode(userinfo)

        #expect(String(decoding: encoded, as: UTF8.self) == #""alice""#)
        #expect(try JSONDecoder().decode(RFC_3986.URI.Userinfo.self, from: encoded) == userinfo)
    }
}

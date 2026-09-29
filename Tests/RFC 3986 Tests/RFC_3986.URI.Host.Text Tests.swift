#if Coder
import ASCII
import RFC_3986
import Testing

@Suite
struct `RFC 3986 Host Text Tests` {

    private func text(_ host: RFC_3986.URI.Host) -> String {
        var codes: [ASCII.Code] = []
        RFC_3986.URI.Host.Text().serialize(host, into: &codes)
        return String(decoding: codes.map(\.underlying), as: UTF8.self)
    }

    @Test
    func `a registered name serializes as written`() throws {
        #expect(text(try RFC_3986.URI.Host("example.com")) == "example.com")
    }

    @Test
    func `an IPv4 address serializes in dotted decimal`() throws {
        #expect(text(try RFC_3986.URI.Host("192.0.2.1")) == "192.0.2.1")
    }

    @Test
    func `an IPv6 address serializes canonically in brackets`() throws {
        #expect(text(try RFC_3986.URI.Host("[2001:db8:0:0:0:0:0:1]")) == "[2001:db8::1]")
    }
}
#endif

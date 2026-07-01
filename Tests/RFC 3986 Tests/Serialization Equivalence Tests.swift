import Testing

@testable import RFC_3986

/// [FAM-012] dual-sibling equivalence.
///
/// Every RFC 3986 conformer is a text-protocol dual: it carries both an
/// `ASCII.Serializable` text verb (`ASCII.Code`) and a `Binary.Serializable`
/// wire verb (`Byte`). A URI (and each of its components) travels as ASCII text
/// on the wire — an HTTP request-target, say — so its wire form is exactly its
/// text form projected to bytes. The two independent format-sibling bodies must
/// therefore agree byte-for-byte: `ascii.map(\.byte) == wire`. This suite guards
/// the two bodies (each self-contained, no canonical `.serialized` detour)
/// against drift — in particular the `URI.Host` IPv4/IPv6 arms, whose `Byte`
/// verb composes the IP address's *ASCII* verb (not its raw-octet wire verb).
@Suite
struct `Serialization Equivalence` {

    /// Serializes `value` through both format siblings and asserts the text verb's
    /// output, projected to bytes, equals the wire verb's output.
    private func expectEquivalent<T: ASCII.Serializable & Binary.Serializable>(
        _ value: T,
        _ label: Comment
    ) {
        var ascii: [ASCII.Code] = []
        T.serialize(value, into: &ascii)
        var wire: [Byte] = []
        T.serialize(value, into: &wire)
        #expect(ascii.map(\.byte) == wire, label)
    }

    @Test
    func `Scheme verbs agree`() throws {
        expectEquivalent(try RFC_3986.URI.Scheme("https"), "https")
        expectEquivalent(try RFC_3986.URI.Scheme("ftp"), "ftp")
    }

    @Test
    func `Port verbs agree`() {
        expectEquivalent(RFC_3986.URI.Port(80), "80")
        expectEquivalent(RFC_3986.URI.Port(8080), "8080")
        expectEquivalent(RFC_3986.URI.Port(443), "443")
    }

    @Test
    func `Path verbs agree`() throws {
        expectEquivalent(try RFC_3986.URI.Path("/a/b/c"), "/a/b/c")
        expectEquivalent(try RFC_3986.URI.Path("/"), "/")
    }

    @Test
    func `Query verbs agree`() throws {
        expectEquivalent(try RFC_3986.URI.Query("a=1&b=2"), "a=1&b=2")
    }

    @Test
    func `Fragment verbs agree`() throws {
        expectEquivalent(try RFC_3986.URI.Fragment("section-1"), "section-1")
    }

    @Test
    func `Userinfo verbs agree`() throws {
        expectEquivalent(try RFC_3986.URI.Userinfo("user:pass"), "user:pass")
    }

    @Test
    func `Host verbs agree (registered name)`() throws {
        expectEquivalent(try RFC_3986.URI.Host("example.com"), "example.com")
        expectEquivalent(try RFC_3986.URI.Host("localhost"), "localhost")
    }

    @Test
    func `Host verbs agree (IPv4)`() throws {
        expectEquivalent(try RFC_3986.URI.Host("192.168.1.1"), "192.168.1.1")
        expectEquivalent(try RFC_3986.URI.Host("8.8.8.8"), "8.8.8.8")
    }

    @Test
    func `Host verbs agree (IPv6, bracketed)`() throws {
        expectEquivalent(try RFC_3986.URI.Host("[2001:db8::1]"), "[2001:db8::1]")
        expectEquivalent(try RFC_3986.URI.Host("[::1]"), "[::1]")
    }

    @Test
    func `Host verbs agree (IPv6 with zone)`() throws {
        expectEquivalent(try RFC_3986.URI.Host("[fe80::1%25eth0]"), "[fe80::1%25eth0]")
    }

    @Test
    func `Authority verbs agree (registered name + port)`() throws {
        expectEquivalent(try RFC_3986.URI.Authority("example.com:8080"), "example.com:8080")
        expectEquivalent(try RFC_3986.URI.Authority("user@example.com:8080"), "user@example.com:8080")
    }

    @Test
    func `Authority verbs agree (IPv4 host + port)`() throws {
        expectEquivalent(try RFC_3986.URI.Authority("192.168.1.1:80"), "192.168.1.1:80")
    }

    @Test
    func `Authority verbs agree (IPv6 host + port)`() throws {
        expectEquivalent(try RFC_3986.URI.Authority("[2001:db8::1]:443"), "[2001:db8::1]:443")
    }

    @Test
    func `URI verbs agree`() throws {
        expectEquivalent(
            try RFC_3986.URI("https://user@example.com:8080/path?query=value#frag"),
            "full URI"
        )
        expectEquivalent(try RFC_3986.URI("http://192.168.1.1:80/"), "IPv4 URI")
        expectEquivalent(try RFC_3986.URI("http://[2001:db8::1]:443/path"), "IPv6 URI")
    }
}

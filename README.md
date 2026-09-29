# swift-rfc-3986

Domain model for RFC 3986, the Uniform Resource Identifier generic syntax: `RFC_3986.URI` with its `URI.Scheme`, `URI.Userinfo`, `URI.Authority`, `URI.Host` (IPv4 literal, scoped IPv6 literal or registered name), `URI.Port`, `URI.Path`, `URI.Query` and `URI.Fragment`, each validating on construction from text or ASCII bytes and each carrying its own typed error. The package also carries the character classes of Section 2 (`RFC_3986.CharacterSet`, `RFC_3986.ByteSet`, `RFC_3986.Grammar`), the percent-encoding primitives of Section 2.1 over bytes, dot-segment removal and the reference resolution of Section 5, and the normalization of Section 6. `normalized()` lowercases the scheme and the host text as written (Section 6.2.2.1), normalizes the percent-encoding of the path and query (uppercase triplets, unreserved octets decoded), removes dot segments and drops the default port; it keeps an IP literal in its written form, and the canonical RFC 5952 rendering of an IPv6 host belongs to the coder's serializer. The `RFC 3986 Foundation Integration` product bridges `URI`, `Scheme`, `Userinfo`, `Port`, `Path`, `Query` and `Fragment` to `Codable`.

Everything that renders wire text lives in [swift-rfc-3986-coder](https://github.com/swift-ietf/swift-rfc-3986-coder): the `ASCII.Parseable`, `ASCII.Serializable` and `Binary.Serializable` conformances, the nested `Coder` types with `Coder.Codable`, the composing initializer `RFC_3986.URI.init(scheme:authority:path:query:fragment:)`, and the `Codable` conformances of `URI.Host` and `URI.Authority` (product `RFC 3986 Coder Foundation Integration`).

```swift
import RFC_3986

let uri = try RFC_3986.URI("https://user@example.com:8080/path/to/thing?key=value#section")
uri.scheme?.value                                    // "https"
uri.host                                             // .registeredName("example.com")
uri.port                                             // 8080
uri.path?.description                                // "/path/to/thing"
uri.query?.description                               // "key=value"
uri.fragment?.value                                  // "section"

try RFC_3986.URI("HTTPS://EXAMPLE.COM:443/path").normalized().value
// "https://example.com/path"

try RFC_3986.URI("http://example.com/path/to/resource").resolve("../other").value
// "http://example.com/path/other"

RFC_3986.percentEncode(Array("hello world?".utf8))   // "hello%20world%3F" as bytes
RFC_3986.percentDecode(Array("caf%C3%A9".utf8))      // "café" as bytes
```

For Internationalized Resource Identifiers, which allow Unicode beyond the ASCII repertoire RFC 3986 admits, see [swift-rfc-3987](https://github.com/swift-ietf/swift-rfc-3987).

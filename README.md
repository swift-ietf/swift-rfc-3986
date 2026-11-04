# swift-rfc-3986

Use this package when you need to check, take apart, normalize or resolve URIs, or percent-encode bytes for one. Start from `RFC_3986.URI`, which holds absolute URIs and relative references alike, and from `RFC_3986.percentEncode(_:allowing:)` and `RFC_3986.percentDecode(_:)` for raw bytes. If your identifiers may contain Unicode, use swift-rfc-3987. If you want one URI type that also covers related standards, use swift-uri-standard. For URLs parsed the way browsers do, use swift-whatwg-url. For URI templates, use swift-rfc-6570. For `Codable`, add the `RFC 3986 Foundation Integration` product.

## Laws

- A URI is ASCII only. Text with any other character is refused, so Unicode has to be percent-encoded first. Malformed percent-encoding such as `100%offsale`, and a port that isn't a number, are refused too.
- The empty string is a valid URI, the same-document reference. A relative reference such as `../relative/path`, `?query=value` or `#fragment` is valid, and so is `example.com`, which is read as a path.
- A URI parses its components once, when it's created, and reads of them are safe from any thread.
- `RFC_3986.URI.init(unchecked:)` skips validation. A component that doesn't parse then reads as nil, and a URI without a host has no `base`.
- `RFC_3986.URI.value` keeps the text as written. `RFC_3986.URI.base` keeps the host as written too, so the base of `https://Example.COM:8080/path` is `https://Example.COM:8080`.
- `RFC_3986.URI.normalized()` lowercases the scheme and host, drops the port when it is 80 for `http`, 443 for `https` or 21 for `ftp`, removes dot segments, and normalizes percent-encoding in the path and query. An IPv6 literal is only lowercased, not rewritten in its canonical form.
- Normalizing percent-encoding decodes escapes of unreserved characters and uppercases the hex digits of every other escape, so `%2d` becomes `-` and `%2f` becomes `%2F`. `RFC_3986.URI.normalizePercentEncoding()` does only this, and only in the path and query.
- `RFC_3986.URI.resolve(_:)` follows the reference resolution of RFC 3986 section 5. A reference with a scheme is returned unchanged. A reference with only a query keeps the base path. Dot segments in the merged path are removed.
- `RFC_3986.URI.appendingPathComponent(_:)` percent-encodes the component, including `/`, `?` and `#`, so the component can't add segments, a query or a fragment. It adds a `/` only when the path doesn't already end in one. `RFC_3986.URI.appendingQueryItem(name:value:)` percent-encodes `&`, `=` and `#` in the name and value.
- `RFC_3986.percentEncode(_:allowing:)` writes uppercase hex and by default leaves only unreserved characters as they are. `RFC_3986.percentDecode(_:)` leaves a malformed escape such as `%G0` or a trailing `%` as it is.
- `RFC_3986.URI.isSecure` is true for `https`, `wss` and `ftps`.
- An IPv6 host is written in brackets, with a zone written as `%25` followed by the zone. A host serializes and encodes an IPv6 address in its canonical form, so `[2001:0DB8::1]` becomes `[2001:db8::1]`.
- `RFC_3986.URI.coder` reads only absolute URIs: it needs a scheme. It stops at the first byte that can't continue the URI, such as a space. If parsing fails, the input is left where it started.
- With `RFC 3986 Foundation Integration`, each type encodes as its text, except a port, which encodes as its number.

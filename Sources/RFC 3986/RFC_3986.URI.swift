public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_3986 {
    /// Errors that can occur when working with URIs
    public enum Error: Swift.Error, Hashable, Sendable {
        /// The provided string is not a valid URI per RFC 3986
        case invalidURI(String)

        /// A URI component is invalid or malformed
        case invalidComponent(String)

        /// URI conversion or transformation failed
        case conversionFailed(String)
    }
}

extension RFC_3986.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidURI(let value):
            return
                "Invalid URI: '\(value)'. URIs must follow RFC 3986 syntax and contain only ASCII characters."

        case .invalidComponent(let component):
            return "Invalid URI component: '\(component)'"

        case .conversionFailed(let reason):
            return "URI conversion failed: \(reason)"
        }
    }
}

// MARK: - URI.Representable Protocol

extension RFC_3986 {
    /// Protocol for types that can represent URIs
    ///
    /// Types conforming to this protocol can be used interchangeably wherever a URI
    /// is expected.
    ///
    /// Example:
    /// ```swift
    /// func process(uri: any RFC_3986.URIRepresentable) {
    ///     print(uri.uri.value)
    /// }
    ///
    /// let uri = try RFC_3986.URI("https://example.com")
    /// process(uri: uri)  // Works!
    /// ```
    public protocol URIRepresentable {
        /// The URI representation
        var uri: RFC_3986.URI { get }
    }
}

// MARK: - URI

extension RFC_3986 {
    /// A Uniform Resource Identifier (URI) reference as defined in RFC 3986
    ///
    /// URIs provide a simple and extensible means for identifying a resource.
    /// They use a restricted set of ASCII characters to ensure maximum compatibility
    /// across different systems and protocols.
    ///
    /// RFC 3986 Section 4.1 defines a URI-reference as either:
    /// - An absolute URI with a scheme (e.g., `https://example.com/path`)
    /// - A relative reference without a scheme (e.g., `/path`, `?query`, `#fragment`)
    ///
    /// RFC 3986 defines a generic syntax consisting of a hierarchical sequence of
    /// five components: scheme, authority, path, query, and fragment.
    ///
    /// For protocol-oriented usage with types like `URL`, see the `RFC_3986.URIRepresentable` protocol.
    public struct URI: Hashable, Sendable, Codable {
        fileprivate let cache: Cache
    }
}

extension RFC_3986.URI {
    /// The URI string
    public var value: String { cache.value }
}

extension RFC_3986.URI {
    /// Compares a URI to a string by comparing the URI's string value
    public static func == <S: StringProtocol>(lhs: RFC_3986.URI, rhs: S) -> Bool {
        lhs.value == rhs
    }

    /// Compares a string to a URI by comparing the URI's string value
    public static func == <S: StringProtocol>(lhs: S, rhs: RFC_3986.URI) -> Bool {
        lhs == rhs.value
    }
}

extension RFC_3986.URI {
    // MARK: - Internal Cache

    /// Internal cache for parsed URI components
    ///
    /// Uses a class for reference semantics, enabling shared storage while maintaining
    /// value semantics for the URI struct. Components are parsed once, eagerly, in
    /// `init`, and cached for O(1) subsequent access.
    ///
    /// This is marked `@unchecked Sendable` because every stored property is a `let`
    /// assigned exactly once during `init`, before the instance can escape to any
    /// other thread (the `URI` struct that holds it is itself only handed across
    /// threads afterward, subject to the ordinary happens-before guarantees Swift's
    /// concurrency runtime already provides for publishing an object reference).
    /// There is no post-init mutation for two threads to race on.
    ///
    /// Previously these were `lazy var`s computed on first access. `lazy` in Swift is
    /// **not** thread-safe: two threads racing on first access to the same `lazy var`
    /// can both observe the uninitialized state and both run the initializer
    /// concurrently, or one thread can observe a torn (partially-initialized) write —
    /// undefined behavior on a type claimed `Sendable`. `ParsedComponents` already
    /// computes every raw substring in one pass, so wrapping each into its typed
    /// component is cheap; there is no meaningful laziness to preserve.
    fileprivate final class Cache: @unchecked Sendable {
        let value: String
        let components: ParsedComponents

        let scheme: Scheme?
        let host: Host?
        let port: Port?
        let path: Path?
        let query: Query?
        let fragment: Fragment?

        init(value: String) {
            self.value = value
            let components = Self.parseURI(value)
            self.components = components
            self.scheme = Self.parsed(components.scheme) { try Scheme($0) }
            self.host = Self.parsed(components.host) { try Host($0) }
            self.port = components.port.flatMap { Port($0) }
            // Empty paths are valid in RFC 3986 - they serialize to ""
            // Only nil if there was no path component at all.
            self.path = Self.parsed(components.path) { try Path($0) }
            self.query = Self.parsed(components.query) { try Query($0) }
            self.fragment = Self.parsed(components.fragment) { try Fragment($0) }
        }

        /// Constructs a `Cache` from components already produced by
        /// ``RFC_3986/URI/Cache/_parseAndValidate(_:)``, so the throwing
        /// string initializer parses the grammar exactly once instead of
        /// parsing again here to populate the cache.
        init(value: String, components: ParsedComponents) {
            self.value = value
            self.components = components
            self.scheme = Self.parsed(components.scheme) { try Scheme($0) }
            self.host = Self.parsed(components.host) { try Host($0) }
            self.port = components.port.flatMap { Port($0) }
            self.path = Self.parsed(components.path) { try Path($0) }
            self.query = Self.parsed(components.query) { try Query($0) }
            self.fragment = Self.parsed(components.fragment) { try Fragment($0) }
        }

        /// Converts a typed-throws component parse into an optional: `nil`
        /// input yields `nil`, and a thrown error is swallowed to `nil` —
        /// exactly the former `try?` behavior, but with the catch made
        /// explicit per [IMPL-108] instead of silently discarding the error.
        private static func parsed<Value, Failure: Swift.Error>(
            _ string: String?,
            _ makeValue: (String) throws(Failure) -> Value
        ) -> Value? {
            guard let string else { return nil }
            do throws(Failure) {
                return try makeValue(string)
            } catch {
                return nil
            }
        }
    }
}

extension RFC_3986.URI.Cache {
    /// Temporary struct to hold parsed URI components
    struct ParsedComponents {
        let scheme: String?
        let userinfo: String?
        let host: String?
        let port: UInt16?
        let path: String?
        let query: String?
        let fragment: String?
    }

    /// Parses a URI string according to RFC 3986 Appendix B
    ///
    /// Uses the regex from RFC 3986 Appendix B:
    /// ^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?
    ///
    /// Groups:
    /// - 2: scheme
    /// - 4: authority
    /// - 5: path
    /// - 7: query
    /// - 9: fragment
    fileprivate static func parseURI(_ uri: String) -> ParsedComponents {
        var scheme: String?
        var authority: String?
        var path: String?
        var query: String?
        var fragment: String?

        var remaining = uri

        // Parse fragment: #(.*)
        if let fragmentIndex = remaining.lastIndex(of: "#") {
            fragment = String(remaining[remaining.index(after: fragmentIndex)...])
            remaining = String(remaining[..<fragmentIndex])
        }

        // Parse query: \?([^#]*)
        if let queryIndex = remaining.lastIndex(of: "?") {
            query = String(remaining[remaining.index(after: queryIndex)...])
            remaining = String(remaining[..<queryIndex])
        }

        // Parse scheme: ([^:/?#]+):
        if let colonIndex = remaining.firstIndex(of: ":"),
            colonIndex > remaining.startIndex
        {
            let schemeCandidate = String(remaining[..<colonIndex])
            // Verify no /, ?, or # appear before the colon
            if !schemeCandidate.contains("/") && !schemeCandidate.contains("?")
                && !schemeCandidate.contains("#")
            {
                scheme = schemeCandidate
                remaining = String(remaining[remaining.index(after: colonIndex)...])
            }
        }

        // Parse authority: //([^/?#]*)
        if remaining.hasPrefix("//") {
            let afterSlashes = remaining.index(remaining.startIndex, offsetBy: 2)
            var authorityEnd = remaining.endIndex

            // Find the first /, ?, or # after //
            for char in ["/", "?", "#"] {
                if let index = remaining[afterSlashes...].firstIndex(of: Character(char)) {
                    if index < authorityEnd {
                        authorityEnd = index
                    }
                }
            }

            authority = String(remaining[afterSlashes..<authorityEnd])
            remaining = String(remaining[authorityEnd...])
        }

        // What remains is the path
        if !remaining.isEmpty {
            path = remaining
        }

        // Parse authority into userinfo, host, and port
        var userinfo: String?
        var host: String?
        var port: UInt16?
        if let auth = authority {
            (userinfo, host, port) = parseAuthority(auth)
        }

        return ParsedComponents(
            scheme: scheme,
            userinfo: userinfo,
            host: host,
            port: port,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    /// Parses authority into userinfo, host, and port
    /// authority = [ userinfo "@" ] host [ ":" port ]
    fileprivate static func parseAuthority(
        _ authority: String
    ) -> (userinfo: String?, host: String?, port: UInt16?) {
        var remaining = authority
        var userinfo: String?

        // Capture userinfo if present (everything before the last @)
        if let atIndex = remaining.lastIndex(of: "@") {
            userinfo = String(remaining[..<atIndex])
            remaining = String(remaining[remaining.index(after: atIndex)...])
        }

        // Check for port (: followed by digits at the end)
        if let colonIndex = remaining.lastIndex(of: ":") {
            let hostPart = String(remaining[..<colonIndex])
            let portPart = String(remaining[remaining.index(after: colonIndex)...])

            if let portValue = UInt16(portPart) {
                return (userinfo, hostPart.isEmpty ? nil : hostPart, portValue)
            }
        }

        return (userinfo, remaining.isEmpty ? nil : remaining, nil)
    }
}

// MARK: - Grammar-Derived Validation

extension RFC_3986.URI.Cache {
    /// Parses `string` and validates it against the RFC 3986 `URI-reference`
    /// grammar (Section 4.1), returning the split components only if the string is
    /// actually grammatical — or `nil` if it is not.
    ///
    /// This replaces the historical approach of validating with an explicit
    /// forbidden-character blocklist (`< > { } | \ ^ \`` plus space/control
    /// characters) layered on top of a permissive ad hoc splitter. A blocklist can
    /// only reject what someone remembered to list; it says nothing about whether
    /// the string actually has the shape of a URI reference. Here, validity is
    /// *derived* from the grammar instead:
    ///
    /// - Every non-empty component's raw bytes are checked against that
    ///   production's actual RFC 3986 character class (composing the `_is*Char`
    ///   grammars in ``RFC_3986/Parse``) plus well-formed `%HH` percent-encoding
    ///   (Section 2.1) via ``RFC_3986/Parse/_isGrammarValid(_:allowedRawByte:)``.
    /// - `host` is delegated to `Host`'s own typed, validating initializer, which
    ///   already implements `IP-literal / IPv4address / reg-name` (Section 3.2.2)
    ///   — a byte-class scan alone cannot distinguish those forms.
    /// - The `path-noscheme` restriction (Section 3.3: when there is neither a
    ///   scheme nor an authority, the first path segment must not contain an
    ///   unencoded `:`, or it would be ambiguous with a scheme) is checked
    ///   explicitly, since the splitter does not enforce it structurally.
    ///
    /// Any byte outside its production's grammar — including every character the
    /// old blocklist enumerated by hand — fails to match and the whole string is
    /// rejected, so this is a strict tightening, not a relaxation.
    static func _parseAndValidate(_ string: String) -> ParsedComponents? {
        // URI references are ASCII-only (RFC 3986 Section 3).
        guard string.utf8.allSatisfy({ $0 < 0x80 }) else { return nil }

        let components = parseURI(string)

        // scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ) — no pct-encoded
        // alternative, so this is a raw byte-class check, not `_isGrammarValid`.
        if let scheme = components.scheme {
            guard RFC_3986.Parse._isValidScheme(scheme.utf8) else { return nil }
        }

        // userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
        if let userinfo = components.userinfo {
            guard
                RFC_3986.Parse._isGrammarValid(
                    userinfo.utf8,
                    allowedRawByte: RFC_3986.Parse._isUserinfoChar
                )
            else { return nil }
        }

        // host = IP-literal / IPv4address / reg-name (Section 3.2.2) — delegate to
        // the typed validator; a byte-class scan cannot tell IP-literal brackets
        // and IPv4 dotted-decimal apart from an invalid reg-name.
        if let host = components.host {
            do throws(RFC_3986.URI.Host.Error) {
                _ = try RFC_3986.URI.Host(host)
            } catch {
                return nil
            }
        }

        // path = *( pchar / "/" )
        if let path = components.path {
            guard
                RFC_3986.Parse._isGrammarValid(
                    path.utf8,
                    allowedRawByte: { RFC_3986.Parse._isPchar($0) || $0 == 0x2F }
                )
            else { return nil }

            // path-noscheme: without a scheme and without an authority, the first
            // segment must not contain an unencoded ":" (Section 3.3).
            if components.scheme == nil, components.host == nil, !path.hasPrefix("/") {
                let firstSegment = path.prefix(while: { $0 != "/" })
                guard !firstSegment.contains(":") else { return nil }
            }
        }

        // query = *( pchar / "/" / "?" )
        if let query = components.query {
            guard
                RFC_3986.Parse._isGrammarValid(
                    query.utf8,
                    allowedRawByte: RFC_3986.Parse._isQueryOrFragmentChar
                )
            else { return nil }
        }

        // fragment = *( pchar / "/" / "?" )
        if let fragment = components.fragment {
            guard
                RFC_3986.Parse._isGrammarValid(
                    fragment.utf8,
                    allowedRawByte: RFC_3986.Parse._isQueryOrFragmentChar
                )
            else { return nil }
        }

        return components
    }
}

// MARK: - Serializable

extension RFC_3986.URI: ASCII.Serializable, Binary.Serializable {
    /// Own `ASCII.Serializable` verb ([FAM-012]) — emits the validated/cached
    /// URI string directly onto the `ASCII.Code` substrate (the URI value is
    /// ASCII-only per RFC 3986; no byte-detour). Output is identical to the
    /// Binary witness body (`serializeBytes`).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in value.value.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    /// Explicit `Binary.Serializable` witness disambiguating the two
    /// constraint-incomparable `serialize(_:into:)` defaults.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    /// Byte-domain serialization body (the validated/cached URI string).
    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ uri: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: uri.value.utf8)
    }
}

// MARK: - Parseable

extension RFC_3986.URI: ASCII.Parseable {
    /// Parses URI from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 URIs follow the generic syntax: scheme ":" hier-part [ "?" query ] [ "#" fragment ]
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI (structured data)
    ///
    /// ## RFC 3986 Section 3
    ///
    /// ```
    /// URI = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
    /// hier-part = "//" authority path-abempty / path-absolute / path-rootless / path-empty
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the URI
    /// - Throws: `RFC_3986.Error` if the bytes are malformed
    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(RFC_3986.Error)
    where Bytes.Element == Byte {
        let string = String(decoding: bytes, as: UTF8.self)
        guard RFC_3986.isValidURI(string) else {
            throw RFC_3986.Error.invalidURI(string)
        }
        self.init(__unchecked: (), value: string)
    }
}

// MARK: - Initialization

extension RFC_3986.URI {
    /// Creates a URI from a string with validation
    ///
    /// - Parameter value: The URI string
    /// - Throws: RFC_3986.Error if the string is not a valid URI
    public init(_ value: some StringProtocol) throws(RFC_3986.Error) {
        let stringValue = String(value)

        // Same-document reference (RFC 3986 Section 4.4): the empty string is not
        // itself matched by the URI-reference grammar, but is explicitly valid.
        if stringValue.isEmpty {
            self.cache = Cache(value: stringValue)
            return
        }

        // Parses the full `URI-reference` grammar once into typed components,
        // deriving validity from the parse itself (see `Cache._parseAndValidate`)
        // instead of gating on a character blocklist. The resulting components are
        // handed straight to `Cache` so the grammar is not parsed a second time.
        guard let components = Cache._parseAndValidate(stringValue) else {
            throw RFC_3986.Error.invalidURI(stringValue)
        }
        self.cache = Cache(value: stringValue, components: components)
    }

    /// Creates a URI WITHOUT validation
    ///
    /// **Warning**: Bypasses RFC 3986 validation.
    /// Only use with compile-time constants or pre-validated values.
    ///
    /// - Parameters:
    ///   - unchecked: Void parameter to prevent accidental use
    ///   - value: The URI string (unchecked)
    init(
        __unchecked _: Void,
        value: String
    ) {
        self.cache = Cache(value: value)
    }

    /// Creates a URI from a string without validation
    ///
    /// This is an internal optimization for cases where validation has already
    /// been performed (e.g., for static constants or when the string is known to be valid).
    ///
    /// - Warning: This does not perform validation. For public use, use `try!` with
    ///   the throwing initializer to make the risk explicit.
    ///
    /// - Parameter value: The URI reference string (must be valid, not validated)
    public init(unchecked value: String) {
        self.init(__unchecked: (), value: value)
    }

    /// Creates a URI from validated RFC 3986 component types
    ///
    /// This initializer constructs a URI from typed components. Since all components
    /// are already validated RFC types, this cannot fail.
    ///
    /// - Parameters:
    ///   - scheme: The URI scheme
    ///   - authority: The authority component (userinfo, host, port)
    ///   - path: The path component
    ///   - query: The query component
    ///   - fragment: The fragment component
    ///
    /// Example:
    /// ```swift
    /// let uri = RFC_3986.URI(
    ///     scheme: try .init("https"),
    ///     authority: .init(
    ///         userinfo: nil,
    ///         host: try .init("example.com"),
    ///         port: .init(443)
    ///     ),
    ///     path: try .init("/path"),
    ///     query: try .init("key=value"),
    ///     fragment: nil
    /// )
    /// ```
    public init(
        scheme: Scheme,
        authority: Authority,
        path: Path,
        query: Query? = nil,
        fragment: Fragment? = nil
    ) {
        var uriString = "\(scheme.value)://"

        if let userinfo = authority.userinfo {
            uriString += "\(userinfo.rawValue)@"
        }

        uriString += authority.host.rawValue

        if let port = authority.port {
            uriString += ":\(port.value)"
        }

        uriString += path.description

        if let query {
            uriString += "?\(query.description)"
        }

        if let fragment {
            uriString += "#\(fragment.value)"
        }

        self.cache = Cache(value: uriString)
    }
}

// MARK: - Component Properties

extension RFC_3986.URI {
    /// The scheme component of this URI
    ///
    /// Per RFC 3986 Section 3.1, the scheme is the first component of a URI
    /// and is followed by a colon. Scheme names consist of a sequence of characters
    /// beginning with a letter and followed by any combination of letters, digits,
    /// plus (+), period (.), or hyphen (-).
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var scheme: Scheme? {
        cache.scheme
    }

    /// The userinfo component of this URI
    ///
    /// Per RFC 3986 Section 3.2.1, the userinfo subcomponent may consist of
    /// a user name and, optionally, scheme-specific information about how to
    /// gain authorization to access the resource. The userinfo, if present,
    /// is followed by a commercial at-sign ("@") that delimits it from the host.
    ///
    /// Note: The userinfo component is deprecated per RFC 3986 Section 3.2.1
    /// for security reasons (passwords in URIs are insecure), but is still
    /// part of the URI syntax for compatibility.
    public var userinfo: Userinfo? {
        // Parse userinfo from the full authority section
        // authority = [ userinfo "@" ] host [ ":" port ]
        // We need to re-parse the original URI to extract userinfo

        // Find the authority section (between // and the next /, ?, or #)
        var remaining = cache.value

        // Skip scheme if present
        if let colonIndex = remaining.firstIndex(of: ":") {
            remaining = String(remaining[remaining.index(after: colonIndex)...])
        }

        // Check for authority (starts with //)
        guard remaining.hasPrefix("//") else { return nil }
        let afterSlashes = remaining.index(remaining.startIndex, offsetBy: 2)
        var authorityEnd = remaining.endIndex

        // Find the end of authority
        for char in ["/", "?", "#"] {
            if let index = remaining[afterSlashes...].firstIndex(of: Character(char)) {
                if index < authorityEnd {
                    authorityEnd = index
                }
            }
        }

        let authority = String(remaining[afterSlashes..<authorityEnd])

        // Extract userinfo (everything before @)
        guard let atIndex = authority.firstIndex(of: "@") else { return nil }
        let userinfoString = String(authority[..<atIndex])

        do throws(Userinfo.Error) {
            return try Userinfo(userinfoString)
        } catch {
            return nil
        }
    }

    /// The host component of this URI
    ///
    /// Per RFC 3986 Section 3.2.2, the host is identified by an IP literal,
    /// IPv4 address, or registered name.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var host: Host? {
        cache.host
    }

    /// The port component of this URI
    ///
    /// Per RFC 3986 Section 3.2.3, the port is designated by an optional decimal
    /// port number following the host and delimited from it by a colon.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var port: Port? {
        cache.port
    }

    /// The path component of this URI
    ///
    /// Per RFC 3986 Section 3.3, the path contains data that identifies a resource
    /// within the scope of the URI's scheme and authority.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var path: Path? {
        cache.path
    }

    /// The query component of this URI
    ///
    /// Per RFC 3986 Section 3.4, the query contains non-hierarchical data that
    /// identifies a resource in conjunction with the scheme and authority.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var query: Query? {
        cache.query
    }

    /// The fragment component of this URI
    ///
    /// Per RFC 3986 Section 3.5, the fragment allows indirect identification
    /// of a secondary resource by reference to a primary resource.
    ///
    /// Components are lazily parsed and cached for O(1) access after first use.
    public var fragment: Fragment? {
        cache.fragment
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI {
    /// Indicates whether this URI is a relative reference
    ///
    /// Per RFC 3986 Section 4.2, a relative reference does not begin with a scheme.
    /// Examples: `//example.com/path`, `/path`, `path`, `?query`, `#fragment`
    ///
    /// - Returns: true if this is a relative reference, false if absolute
    public var isRelative: Bool {
        scheme == nil
    }

    /// Returns `true` if this URI uses a secure scheme (https, wss, and similar)
    public var isSecure: Bool {
        guard let uriScheme = scheme?.value else { return false }
        return ["https", "wss", "ftps"].contains(uriScheme)
    }

    /// Returns `true` if this URI is an HTTP or HTTPS URI
    public var isHTTP: Bool {
        guard let uriScheme = scheme?.value else { return false }
        return uriScheme == "http" || uriScheme == "https"
    }

    /// Returns the base URI (scheme + authority) without path, query, or fragment
    ///
    /// Example: `https://example.com:8080/path?query#fragment` → `https://example.com:8080`
    public var base: RFC_3986.URI? {
        guard let uriScheme = scheme,
            let uriHost = host
        else { return nil }

        var baseString = "\(uriScheme.value)://\(uriHost.rawValue)"
        if let uriPort = port {
            baseString += ":\(uriPort.value)"
        }
        return RFC_3986.URI(unchecked: baseString)
    }

    /// Returns the path and query components combined
    ///
    /// Example: `/path?key=value`
    public var pathAndQuery: String? {
        guard let uriPath = path else { return nil }
        if let uriQuery = query {
            return "\(uriPath.description)?\(uriQuery.description)"
        }
        return uriPath.description
    }
}

// MARK: - URI Operations

extension RFC_3986.URI {
    /// Returns a normalized version of this URI
    ///
    /// Per RFC 3986 Section 6, normalization includes:
    /// - Case normalization of scheme and host (Section 6.2.2.1)
    /// - Percent-encoding normalization (Section 6.2.2.2)
    /// - Path segment normalization (Section 6.2.2.3)
    /// - Removal of default ports
    ///
    /// - Returns: A normalized URI
    public func normalized() -> RFC_3986.URI {
        // Get components
        let normalizedScheme = scheme?.value.lowercased()
        let normalizedHost = host?.rawValue.lowercased()
        var normalizedPort = port
        var normalizedPath = path?.description
        var normalizedQuery = query?.description
        let normalizedFragment = fragment?.value

        // Remove default ports
        if let scheme = normalizedScheme, let port = normalizedPort {
            let isDefaultPort =
                (scheme == "http" && port == 80) || (scheme == "https" && port == 443)
                || (scheme == "ftp" && port == 21)
            if isDefaultPort {
                normalizedPort = nil
            }
        }

        // Normalize path by removing dot segments (Section 6.2.2.3)
        if let pathString = normalizedPath, !pathString.isEmpty {
            normalizedPath = RFC_3986.removeDotSegments(from: pathString)
        }

        // Normalize percent-encoding (Section 6.2.2.2)
        if let pathString = normalizedPath {
            normalizedPath = RFC_3986.normalizePercentEncoding(pathString)
        }
        if let queryString = normalizedQuery {
            normalizedQuery = RFC_3986.normalizePercentEncoding(queryString)
        }

        // Reconstruct URI
        var result = ""
        if let scheme = normalizedScheme {
            result += "\(scheme):"
        }
        if let host = normalizedHost {
            result += "//\(host)"
            if let port = normalizedPort {
                result += ":\(port)"
            }
        }
        if let path = normalizedPath {
            result += path
        }
        if let query = normalizedQuery {
            result += "?\(query)"
        }
        if let fragment = normalizedFragment {
            result += "#\(fragment)"
        }

        return RFC_3986.URI(unchecked: result)
    }

    /// Normalizes percent-encoding per RFC 3986 Section 6.2.2.2
    ///
    /// This method:
    /// - Uppercases hex digits in percent-encoded octets
    /// - Decodes percent-encoded unreserved characters
    ///
    /// Example:
    /// ```swift
    /// let uri = try RFC_3986.URI("https://example.com/hello%2dworld")
    /// let normalized = uri.normalizePercentEncoding()
    /// // URI with path "hello-world" (decoded unreserved hyphen)
    /// ```
    ///
    /// - Returns: A new URI with normalized percent-encoding
    public func normalizePercentEncoding() -> RFC_3986.URI {
        var normalizedPath = path?.description
        var normalizedQuery = query?.description

        // Normalize percent-encoding in path
        if let pathString = normalizedPath {
            normalizedPath = RFC_3986.normalizePercentEncoding(pathString)
        }

        // Normalize percent-encoding in query
        if let queryString = normalizedQuery {
            normalizedQuery = RFC_3986.normalizePercentEncoding(queryString)
        }

        // Reconstruct URI with normalized components
        var result = ""
        if let scheme = scheme?.value {
            result += "\(scheme):"
        }

        // Add authority if present
        if let host = host?.rawValue {
            result += "//"
            if let userinfo = userinfo?.rawValue {
                result += "\(userinfo)@"
            }
            result += host
            if let port {
                result += ":\(port)"
            }
        }

        if let path = normalizedPath {
            result += path
        }
        if let query = normalizedQuery {
            result += "?\(query)"
        }
        if let fragment = fragment?.value {
            result += "#\(fragment)"
        }

        return RFC_3986.URI(unchecked: result)
    }

    /// Resolves a relative URI reference against this URI as a base
    ///
    /// Per RFC 3986 Section 5, this implements the URI resolution algorithm
    /// to convert a relative reference into an absolute URI.
    ///
    /// - Parameter reference: The URI reference to resolve (may be relative or absolute)
    /// - Returns: The resolved absolute URI
    /// - Throws: RFC_3986.Error if resolution fails
    public func resolve(_ reference: RFC_3986.URI) throws(RFC_3986.Error) -> RFC_3986.URI {
        try resolve(reference.value)
    }

    /// Resolves a relative URI reference against this URI as a base
    ///
    /// Per RFC 3986 Section 5, this implements the URI resolution algorithm
    /// to convert a relative reference into an absolute URI.
    ///
    /// - Parameter reference: The URI reference string to resolve
    /// - Returns: The resolved absolute URI
    /// - Throws: RFC_3986.Error if resolution fails
    public func resolve(_ reference: some StringProtocol) throws(RFC_3986.Error) -> RFC_3986.URI {
        // TODO: Implement full RFC 3986 Section 5 resolution algorithm
        // For now, this is a simplified implementation

        let refURI = try RFC_3986.URI(reference)

        // If reference has a scheme, it's absolute - return it as-is
        if refURI.scheme != nil {
            return refURI
        }

        // If reference has authority, use base scheme + reference authority/path/query
        if refURI.host != nil {
            var result = ""
            if let baseScheme = scheme {
                result += "\(baseScheme.value):"
            }
            result += "//"
            if let refHost = refURI.host {
                result += refHost.rawValue
            }
            if let refPort = refURI.port {
                result += ":\(refPort)"
            }
            if let refPath = refURI.path {
                result += refPath.description
            }
            if let refQuery = refURI.query {
                result += "?\(refQuery.description)"
            }
            if let refFragment = refURI.fragment {
                result += "#\(refFragment.value)"
            }
            return RFC_3986.URI(unchecked: result)
        }

        // Reference has no scheme or authority - merge paths
        var result = ""
        if let baseScheme = scheme {
            result += "\(baseScheme.value):"
        }
        if let baseHost = host {
            result += "//\(baseHost.rawValue)"
            if let basePort = port {
                result += ":\(basePort)"
            }
        }

        // Merge paths according to RFC 3986 Section 5.2.3
        let refPath = refURI.path?.description
        var mergedPath = ""
        if let refPath, !refPath.isEmpty {
            if refPath.hasPrefix("/") {
                // Absolute path - use reference path as-is
                mergedPath = refPath
            } else {
                // Relative path - merge with base
                if let basePath = path?.description {
                    // Remove last segment from base path
                    if let lastSlash = basePath.lastIndex(of: "/") {
                        mergedPath = String(basePath[...lastSlash]) + refPath
                    } else {
                        mergedPath = refPath
                    }
                } else {
                    mergedPath = "/\(refPath)"
                }
            }
            // Remove dot segments from the merged path only (not the whole URI)
            mergedPath = RFC_3986.removeDotSegments(from: mergedPath)
            result += mergedPath
        } else if let basePath = path {
            result += basePath.description
        }

        // Use reference query if present, otherwise use base query
        if let refQuery = refURI.query {
            result += "?\(refQuery.description)"
        } else if refPath == nil, let baseQuery = query {
            result += "?\(baseQuery.description)"
        }

        // Always use reference fragment
        if let refFragment = refURI.fragment {
            result += "#\(refFragment.value)"
        }

        return RFC_3986.URI(unchecked: result)
    }
}

// MARK: - Convenience Methods

extension RFC_3986.URI {
    /// Creates a new URI by appending a path component
    ///
    /// - Parameter component: The path component to append
    /// - Returns: A new URI with the appended path component
    public func appendingPathComponent(_ component: some StringProtocol) -> RFC_3986.URI {
        var result = ""

        // Add scheme
        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        // Add authority
        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        // Percent-encode the caller-supplied component with a pchar-safe set
        // (RFC 3986 Section 3.3: pchar = unreserved / pct-encoded / sub-delims /
        // ":" / "@") before appending. `component` is untrusted, unstructured
        // text — without this, an unencoded "/", "?", or "#" in it would inject
        // extra path segments, a query, or a fragment into what was previously a
        // validated URI.
        let encodedComponent = RFC_3986.percentEncode(String(component), allowing: .pathSegment)

        // Append to path
        let currentPath = path?.description ?? ""
        let separator = currentPath.hasSuffix("/") ? "" : "/"
        result += currentPath + separator + encodedComponent

        // Add query and fragment
        if let uriQuery = query {
            result += "?\(uriQuery.description)"
        }
        if let uriFragment = fragment {
            result += "#\(uriFragment.value)"
        }

        // Use unchecked init since components are already validated
        return RFC_3986.URI(unchecked: result)
    }

    /// Creates a new URI by appending a query parameter
    ///
    /// - Parameters:
    ///   - name: The query parameter name
    ///   - value: The query parameter value
    /// - Returns: A new URI with the appended query parameter
    public func appendingQueryItem(
        name: some StringProtocol,
        value: (some StringProtocol)?
    ) -> RFC_3986.URI {
        var result = ""

        // Add scheme
        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        // Add authority
        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        // Add path
        if let uriPath = path {
            result += uriPath.description
        }

        // Add query with new item. `name`/`value` are untrusted, unstructured
        // text for a single query pair, so they are percent-encoded with
        // `.queryComponent` — a set narrower than `.query` that also encodes
        // "&", "=", and "#" — so they cannot inject additional query pairs or
        // truncate the query into a fragment (see `.queryComponent`'s doc).
        let encodedName = RFC_3986.percentEncode(String(name), allowing: .queryComponent)
        let encodedValue = value.map {
            RFC_3986.percentEncode(String($0), allowing: .queryComponent)
        }

        if let currentQuery = query?.description {
            result += "?\(currentQuery)&\(encodedName)"
            if let value = encodedValue {
                result += "=\(value)"
            }
        } else {
            result += "?\(encodedName)"
            if let value = encodedValue {
                result += "=\(value)"
            }
        }

        // Add fragment
        if let uriFragment = fragment {
            result += "#\(uriFragment.value)"
        }

        // Use unchecked init since components are already validated
        return RFC_3986.URI(unchecked: result)
    }

    /// Creates a new URI by setting the fragment
    ///
    /// - Parameter fragment: The fragment to set
    /// - Returns: A new URI with the specified fragment
    public func settingFragment(_ fragment: Fragment?) -> RFC_3986.URI {
        var result = ""

        // Add scheme
        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        // Add authority
        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        // Add path
        if let uriPath = path {
            result += uriPath.description
        }

        // Add query
        if let uriQuery = query {
            result += "?\(uriQuery.description)"
        }

        // Add new fragment
        if let newFragment = fragment {
            result += "#\(newFragment.value)"
        }

        // Use unchecked init since components are already validated
        return RFC_3986.URI(unchecked: result)
    }
}

// MARK: - Equatable

extension RFC_3986.URI {
    /// Compare URIs based on their string values
    ///
    /// Two URIs are considered equal if their string representations are identical.
    /// The cache is not considered for equality.
    public static func == (lhs: RFC_3986.URI, rhs: RFC_3986.URI) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Hashable

extension RFC_3986.URI {
    /// Hash based on the URI string value
    ///
    /// The cache is not included in the hash.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

// MARK: - Codable

extension RFC_3986.URI {
    /// Decode a URI from a string
    // reason: Decodable's `init(from:) throws` requirement is fixed by the stdlib protocol — `any Decoder` and untyped `throws` cannot be replaced with a generic constraint or typed throws without breaking Codable conformance.
    // swiftlint:disable:next no_any_protocol_existential typed_throws_required
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    /// Encode the URI as a string
    // reason: Encodable's `encode(to:) throws` requirement is fixed by the stdlib protocol — `any Encoder` and untyped `throws` cannot be replaced with a generic constraint or typed throws without breaking Codable conformance.
    // swiftlint:disable:next no_any_protocol_existential typed_throws_required
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Operators

extension RFC_3986.URI {
    /// Resolves a relative URI reference using the `/` operator
    ///
    /// Example:
    /// ```swift
    /// let base = try RFC_3986.URI("https://example.com/path")
    /// let resolved = try base / "../other"
    /// // resolved: https://example.com/other
    /// ```
    public static func / (
        base: RFC_3986.URI,
        reference: String
    ) throws(RFC_3986.Error) -> RFC_3986.URI {
        try base.resolve(reference)
    }

    /// Resolves a relative URI reference using the `/` operator
    public static func / (
        base: RFC_3986.URI,
        reference: RFC_3986.URI
    ) throws(RFC_3986.Error) -> RFC_3986.URI {
        try base.resolve(reference)
    }
}

// MARK: - URI.Representable Conformance

extension RFC_3986.URI {
    /// Typealias for backwards compatibility
    public typealias Representable = RFC_3986.URIRepresentable
}

extension RFC_3986.URI: RFC_3986.URIRepresentable {
    public var uri: RFC_3986.URI {
        self
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI: CustomStringConvertible {
    public var description: String {
        value
    }
}

// MARK: - CustomDebugStringConvertible

extension RFC_3986.URI: CustomDebugStringConvertible {
    public var debugDescription: String {
        var parts: [String] = ["RFC 3986.URI"]

        if let scheme {
            parts.append("scheme: \(scheme)")
        }
        if let host {
            parts.append("host: \(host)")
        }
        if let port {
            parts.append("port: \(port)")
        }
        if let path, !path.isEmpty {
            parts.append("path: \(path)")
        }
        if let query {
            parts.append("query: \(query)")
        }
        if let fragment {
            parts.append("fragment: \(fragment)")
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Comparable

extension RFC_3986.URI: Comparable {
    /// Compares two URIs lexicographically by their string representation
    public static func < (lhs: RFC_3986.URI, rhs: RFC_3986.URI) -> Bool {
        lhs.value < rhs.value
    }
}

// MARK: - Path Normalization

extension RFC_3986 {
    /// Removes dot segments from a path per RFC 3986 Section 5.2.4
    ///
    /// This algorithm removes "." and ".." segments from paths to produce
    /// a normalized path. For example:
    /// - `/a/b/c/./../../g` → `/a/g`
    /// - `/./a/b/` → `/a/b/`
    ///
    /// - Parameter path: The path to normalize
    /// - Returns: The path with dot segments removed
    ///
    /// - Note: Cyclomatic complexity inherent to RFC 3986 Section 5.2.4 algorithm
    // swiftlint:disable cyclomatic_complexity
    public static func removeDotSegments(from path: String) -> String {
        var input = path
        var output = ""

        while !input.isEmpty {
            // A: If the input buffer begins with a prefix of "../" or "./"
            if input.hasPrefix("../") {
                input.removeFirst(3)
            } else if input.hasPrefix("./") {
                input.removeFirst(2)
            }
            // B: If the input buffer begins with a prefix of "/./" or "/."
            else if input.hasPrefix("/./") {
                input = "/" + input.dropFirst(3)
            } else if input == "/." {
                input = "/"
            }
            // C: If the input buffer begins with a prefix of "/../" or "/.."
            else if input.hasPrefix("/../") {
                input = "/" + input.dropFirst(4)
                // Remove the last segment from output
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            } else if input == "/.." {
                input = "/"
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            }
            // D: If the input buffer consists only of "." or ".."
            else if input == "." || input == ".." {
                input = ""
            }
            // E: Move the first path segment to output
            else {
                // Find the next "/" after the first character
                let startIndex = input.index(after: input.startIndex)
                if let slashIndex = input[startIndex...].firstIndex(of: "/") {
                    let segment = String(input[..<slashIndex])
                    output += segment
                    input = String(input[slashIndex...])
                } else {
                    output += input
                    input = ""
                }
            }
        }

        return output
    }
    // swiftlint:enable cyclomatic_complexity
}

// MARK: - Validation Functions

extension RFC_3986 {
    /// Validates if a string is a valid URI reference
    ///
    /// A valid URI reference (per RFC 3986 Section 4.1) is either:
    /// - An absolute URI with a scheme (e.g., `https://example.com/path`)
    /// - A relative reference without a scheme (e.g., `/path`, `?query`, `#fragment`)
    /// - An empty string (representing "same document reference")
    ///
    /// This parses `string` once against the RFC 3986 `URI-reference` grammar
    /// (composing the `scheme` / `userinfo` / `host` / `path` / `query` /
    /// `fragment` productions — see `URI.Cache._parseAndValidate`) and derives
    /// validity from whether that parse succeeds, rather than from an explicit
    /// forbidden-character blocklist. `URI.init(_:)` calls this same underlying
    /// parse so a string is validated and split exactly once on the throwing
    /// construction path.
    ///
    /// - Parameter string: The string to validate
    /// - Returns: true if the string matches the RFC 3986 URI-reference grammar
    public static func isValidURI(_ string: String) -> Bool {
        // Empty strings are allowed (same document reference, Section 4.4)
        if string.isEmpty { return true }

        return RFC_3986.URI.Cache._parseAndValidate(string) != nil
    }

    /// Validates if a URI is a valid HTTP(S) URI
    ///
    /// - Parameter uri: The URI to validate
    /// - Returns: true if the URI is an HTTP or HTTPS URI
    public static func isValidHTTP<Representable: URIRepresentable>(_ uri: Representable) -> Bool {
        guard let scheme = uri.uri.scheme else { return false }
        return scheme.value == "http" || scheme.value == "https"
    }

    /// Validates if a string is a valid HTTP(S) URI
    ///
    /// - Parameter string: The string to validate
    /// - Returns: true if the string is an HTTP or HTTPS URI
    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidURI(string) else { return false }
        let uri: URI
        do throws(RFC_3986.Error) {
            uri = try URI(string)
        } catch {
            return false
        }
        return uri.scheme?.value == "http" || uri.scheme?.value == "https"
    }
}

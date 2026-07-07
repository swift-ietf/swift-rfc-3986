public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import IPv4_Standard
public import IPv6_Standard
public import Parseable_ASCII_Primitives

// MARK: - URI Host

extension RFC_3986.URI {
    /// URI host component per RFC 3986 Section 3.2.2
    ///
    /// The host subcomponent of authority is identified by an IP literal encapsulated
    /// within square brackets, an IPv4 address in dotted-decimal form, or a registered name.
    ///
    /// ## Type Safety
    ///
    /// This implementation uses strongly-typed addresses:
    /// - **IPv4**: `RFC_791.IPv4.Address` for validated dotted-decimal addresses
    /// - **IPv6**: `RFC_4007.IPv6.ScopedAddress` for addresses with optional zone identifiers
    /// - **Registered Name**: `String` for DNS hostnames and other names
    ///
    /// ## Example
    /// ```swift
    /// // IPv4 address
    /// let ipv4 = try RFC_3986.URI.Host("192.168.1.1")
    ///
    /// // IPv6 address (in brackets)
    /// let ipv6 = try RFC_3986.URI.Host("[2001:db8::1]")
    ///
    /// // IPv6 with zone identifier
    /// let scoped = try RFC_3986.URI.Host("[fe80::1%eth0]")
    ///
    /// // Registered name (domain)
    /// let domain = try RFC_3986.URI.Host("example.com")
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// host = IP-literal / IPv4address / reg-name
    /// IP-literal = "[" ( IPv6address / IPvFuture ) "]"
    /// ```
    public enum Host: Sendable, Equatable, Hashable {
        /// IPv4 address in dotted-decimal notation
        ///
        /// Uses `RFC_791.IPv4.Address` for type-safe, validated addresses.
        ///
        /// Example: "192.168.1.1"
        case ipv4(RFC_791.IPv4.Address)

        /// IPv6 address with optional zone identifier
        ///
        /// Uses `RFC_4007.IPv6.ScopedAddress` to support both plain addresses
        /// and scoped addresses with zone identifiers (e.g., `fe80::1%eth0`).
        ///
        /// The zone identifier is serialized within the brackets per RFC 6874:
        /// `[fe80::1%25eth0]` (percent-encoded for URIs)
        ///
        /// Example: "2001:db8::1", "fe80::1%eth0"
        case ipv6(RFC_4007.IPv6.ScopedAddress)

        /// Registered name (DNS hostname or other name)
        ///
        /// Normalized to lowercase per RFC 3986 Section 6.2.2.1.
        ///
        /// Example: "example.com", "localhost"
        case registeredName(String)
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Host: ASCII.Serializable, Binary.Serializable {
    /// [FAM-012] text sibling (`ASCII.Code`) — RFC 3986 §3.2.2 `host`.
    ///
    /// The `.ipv4` / `.ipv6` arms compose their address sub-parts' own canonical
    /// text verbs directly into the `ASCII.Code` sink (clause-9): IPv4 → rfc-791's
    /// dotted-decimal `ASCII.Serializable`; IPv6 → rfc-5952's canonical
    /// `@retroactive` `ASCII.Serializable`, wrapped in Host's own `[`…`]` +
    /// `%25`-zone URI framing (RFC 3986 §3.2.2 / RFC 6874 — Host's own escaping
    /// codec, which the sub-part's address verb cannot provide).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ host: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        switch host {
        case .ipv4(let address):
            RFC_791.IPv4.Address.serialize(address, into: &buffer)

        case .ipv6(let scopedAddress):
            buffer.append(ASCII.Code.leftBracket)
            RFC_4291.IPv6.Address.serialize(scopedAddress.address, into: &buffer)
            if let zone = scopedAddress.zone {
                // RFC 6874: the zone id is percent-encoded (`%` → `%25`) in URIs.
                buffer.append(ASCII.Code.percentSign)
                buffer.append(ASCII.Code.`2`)
                buffer.append(ASCII.Code.`5`)
                for byte in zone.utf8 { buffer.append(ASCII.Code(byte)) }
            }
            buffer.append(ASCII.Code.rightBracket)

        case .registeredName(let name):
            for byte in name.utf8 { buffer.append(ASCII.Code(byte)) }
        }
    }

    /// [FAM-012] binary sibling (`Byte`) — the URI-host **text** as wire bytes.
    ///
    /// A URI host travels as ASCII text on the wire (e.g. an HTTP request-target),
    /// so its wire form is `ascii.map(\.byte)` — NOT the IP address's raw octets.
    /// The `.ipv4` / `.ipv6` arms therefore compose the address sub-parts'
    /// **ASCII** (canonical text) verbs into an `[ASCII.Code]` temp and lift to
    /// `Byte` via `.map(\.byte)` — the ratified text-as-bytes realization (the IP's
    /// `Binary` verb is the raw wire address, which is the wrong format here). The
    /// `ascii.map(\.byte) == wire` equivalence test guards the two bodies against
    /// drift.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ host: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        switch host {
        case .ipv4(let address):
            var codes: [ASCII.Code] = []
            RFC_791.IPv4.Address.serialize(address, into: &codes)
            buffer.append(contentsOf: codes.map(\.byte))

        case .ipv6(let scopedAddress):
            buffer.append(ASCII.Code.leftBracket.byte)
            var codes: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(scopedAddress.address, into: &codes)
            buffer.append(contentsOf: codes.map(\.byte))
            if let zone = scopedAddress.zone {
                // RFC 6874: the zone id is percent-encoded (`%` → `%25`) in URIs.
                buffer.append(ASCII.Code.percentSign.byte)
                buffer.append(ASCII.Code.`2`.byte)
                buffer.append(ASCII.Code.`5`.byte)
                for byte in zone.utf8 { buffer.append(Byte(byte)) }
            }
            buffer.append(ASCII.Code.rightBracket.byte)

        case .registeredName(let name):
            for byte in name.utf8 { buffer.append(Byte(byte)) }
        }
    }
}

// MARK: - Parseable

extension RFC_3986.URI.Host: ASCII.Parseable {
    /// Re-provides the string convenience initializer (previously inherited from
    /// the retired combined ASCII serializable protocol, Void context).
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses host from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 hosts can be: IP-literal / IPv4address / reg-name
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Host (structured data)
    ///
    /// ## RFC 3986 Section 3.2.2
    ///
    /// ```
    /// host = IP-literal / IPv4address / reg-name
    /// IP-literal = "[" ( IPv6address / IPvFuture ) "]"
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the host
    /// - Throws: `RFC_3986.URI.Host.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        let string = String(decoding: bytes, as: UTF8.self)

        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly (RFC 3986 host grammar is strict ASCII).
        // Non-ASCII bytes fail with `invalidCharacter` carrying the offending Byte.
        let arr: [ASCII.Code]
        do {
            arr = try [ASCII.Code](bytes)
        } catch {
            switch error {
            case .notASCII(let byte):
                throw Error.invalidCharacter(string, byte: byte, reason: "non-ASCII byte in host")
            }
        }

        // Check for IP-literal (enclosed in brackets)
        if arr.first == ASCII.Code.leftBracket {
            // Check that it ends with ']'
            guard arr.last == ASCII.Code.rightBracket else {
                throw Error.invalidIPv6(string, reason: "Missing closing bracket")
            }

            // Extract content between brackets
            let innerCodes = arr.dropFirst().dropLast()

            // Check for zone identifier (% encoded as %25 in URIs per RFC 6874)
            // In URI format: [fe80::1%25eth0]
            // We need to decode %25 back to % for the scoped address parser
            let innerArray = Array(innerCodes)
            var decodedBytes: [Byte] = []
            decodedBytes.reserveCapacity(innerArray.count)

            var i = 0
            while i < innerArray.count {
                if innerArray[i] == ASCII.Code.percentSign {
                    // Check for %25 (percent-encoded percent)
                    if i + 2 < innerArray.count
                        && innerArray[i + 1] == ASCII.Code.`2`
                        && innerArray[i + 2] == ASCII.Code.`5`
                    {
                        // Decode %25 to %
                        decodedBytes.append(ASCII.Code.percentSign)
                        i += 3
                        continue
                    }
                }
                decodedBytes.append(innerArray[i])
                i += 1
            }

            // Try to parse as IPv6 scoped address
            do {
                let scopedAddress = try RFC_4007.IPv6.ScopedAddress(ascii: decodedBytes)
                self = .ipv6(scopedAddress)
                return
            } catch {
                let innerString = String(decoding: innerCodes, as: UTF8.self)
                throw Error.invalidIPv6(innerString, reason: "Invalid IPv6 address")
            }
        }

        // Try to parse as IPv4 address
        do {
            let ipv4Address = try RFC_791.IPv4.Address(ascii: bytes)
            self = .ipv4(ipv4Address)
            return
        } catch {
            // Not a valid IPv4 - continue to registered name
        }

        // Otherwise treat as registered name
        // Validate registered name characters at byte level
        for code in arr {
            // unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
            // sub-delims: "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
            // plus percent-encoding "%"
            let isUnreserved =
                code.isLetter || code.isDigit
                || code == ASCII.Code.hyphen || code == ASCII.Code.period
                || code == ASCII.Code.underline || code == ASCII.Code.tilde
            let isSubDelim =
                code == ASCII.Code.exclamationPoint || code == ASCII.Code.dollarSign
                || code == ASCII.Code.ampersand || code == ASCII.Code.apostrophe
                || code == ASCII.Code.leftParenthesis || code == ASCII.Code.rightParenthesis
                || code == ASCII.Code.asterisk || code == ASCII.Code.plusSign
                || code == ASCII.Code.comma || code == ASCII.Code.semicolon
                || code == ASCII.Code.equalsSign
            let isPercent = code == ASCII.Code.percentSign

            guard isUnreserved || isSubDelim || isPercent else {
                throw Error.invalidCharacter(
                    string,
                    byte: code.byte,
                    reason:
                        "Only unreserved, sub-delims, and percent-encoded allowed in registered name"
                )
            }
        }

        // Normalize to lowercase per RFC 3986 Section 6.2.2.1
        self = .registeredName(string.lowercased())
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Host: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Host {
    /// The raw string representation of the host
    ///
    /// For IPv6, this includes the surrounding brackets and percent-encoded zone.
    /// For IPv4 and registered names, returns the value as-is.
    public var rawValue: String {
        String(decoding: serialized, as: UTF8.self)
    }

    /// Returns true if this is a loopback address
    public var isLoopback: Bool {
        switch self {
        case .ipv4(let address):
            // IPv4 loopback: 127.0.0.0/8 (any 127.x.x.x)
            return address.octets.0 == 127
        case .ipv6(let scopedAddress):
            return scopedAddress.address.is.loopback
        case .registeredName(let name):
            return name == "localhost"
        }
    }

    /// The IPv4 address if this host is an IPv4 address
    public var ipv4Address: RFC_791.IPv4.Address? {
        if case .ipv4(let address) = self {
            return address
        }
        return nil
    }

    /// The IPv6 scoped address if this host is an IPv6 address
    public var ipv6ScopedAddress: RFC_4007.IPv6.ScopedAddress? {
        if case .ipv6(let scopedAddress) = self {
            return scopedAddress
        }
        return nil
    }

    /// The IPv6 address if this host is an IPv6 address (without zone)
    public var ipv6Address: RFC_4291.IPv6.Address? {
        if case .ipv6(let scopedAddress) = self {
            return scopedAddress.address
        }
        return nil
    }

    /// The registered name if this host is a registered name
    public var registeredNameValue: String? {
        if case .registeredName(let name) = self {
            return name
        }
        return nil
    }
}

// MARK: - Codable

extension RFC_3986.URI.Host: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

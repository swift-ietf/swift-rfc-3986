public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

// MARK: - URI Userinfo

extension RFC_3986.URI {
    /// URI userinfo component per RFC 3986 Section 3.2.1
    ///
    /// The userinfo subcomponent may consist of a user name and, optionally,
    /// scheme-specific information about how to gain authorization to access
    /// the resource.
    ///
    /// ## Security Note
    ///
    /// **The use of userinfo in URIs is deprecated** per RFC 3986 Section 3.2.1:
    /// - Passing authentication credentials in URIs is insecure
    /// - Applications should not render userinfo unless data is masked
    /// - Modern applications should use proper authentication mechanisms (OAuth, etc.)
    ///
    /// This type exists for RFC compliance and parsing legacy URIs only.
    ///
    /// ## Example
    /// ```swift
    /// // Simple username
    /// let username = try RFC_3986.URI.Userinfo("john")
    ///
    /// // Username with password (deprecated, insecure)
    /// let withPassword = try RFC_3986.URI.Userinfo("john:secret")
    ///
    /// // Access components
    /// print(withPassword.user)      // "john"
    /// print(withPassword.password)  // "secret"
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
    /// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
    /// pct-encoded = "%" HEXDIG HEXDIG
    /// sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
    /// ```
    public struct Userinfo: Sendable, Equatable, Hashable, Codable {
        /// RawValue type for RawRepresentable conformance
        public typealias RawValue = String

        /// The raw userinfo string (may contain username:password)
        public let rawValue: String

        /// Creates a userinfo component WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw userinfo value (unchecked)
        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Userinfo: Swift.RawRepresentable, Serializable, ASCII.Serializable, Binary.Serializable {
    /// Re-provides the `Swift.RawRepresentable` requirement (previously inherited
    /// from the retired combined ASCII serializable protocol).
    public init?(rawValue: String) {
        try? self.init(rawValue)
    }

    /// Explicit `Binary.Serializable` witness: disambiguates the two
    /// constraint-incomparable `serialize(_:into:)` defaults. The bytes derive
    /// from the free `[ASCII.Code]` serializer supplied by the `String`-RawRepresentable default.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.serialized)
    }
}

// MARK: - Parseable

extension RFC_3986.URI.Userinfo: ASCII.Parseable {
    /// Re-provides the string convenience initializer (previously inherited from
    /// the retired combined ASCII serializable protocol, Void context).
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses userinfo from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 userinfo follows the pattern: *( unreserved / pct-encoded / sub-delims / ":" )
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Userinfo (structured data)
    ///
    /// ## RFC 3986 Section 3.2.1
    ///
    /// ```
    /// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the userinfo
    /// - Throws: `RFC_3986.URI.Userinfo.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly (RFC 3986 userinfo grammar is strict ASCII).
        // Non-ASCII bytes fail with `invalidCharacter` carrying the offending Byte.
        let arr: [ASCII.Code]
        do {
            arr = try Array<ASCII.Code>(bytes)
        } catch {
            switch error {
            case .notASCII(let byte):
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "non-ASCII byte in userinfo"
                )
            }
        }

        // Validate userinfo characters at byte level
        var i = 0
        while i < arr.count {
            let code = arr[i]

            // Check for percent-encoding
            if code == ASCII.Code.percentSign {
                // Validate percent-encoding: must have 2 hex digits following
                let next1 = i + 1
                guard next1 < arr.count else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "'%' must be followed by 2 hex digits"
                    )
                }
                let next2 = next1 + 1
                guard next2 < arr.count else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "'%' must be followed by 2 hex digits"
                    )
                }

                guard arr[next1].isHexDigit && arr[next2].isHexDigit else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "Invalid hex digits after '%'"
                    )
                }

                // Skip past the percent-encoded sequence
                i = next2 + 1
                continue
            }

            // Check if valid userinfo character
            // unreserved: ALPHA / DIGIT / "-" / "." / "_" / "~"
            // sub-delims: "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
            // plus ":"
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
            let isColon = code == ASCII.Code.colon

            guard isUnreserved || isSubDelim || isColon else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte,
                    reason: "Only unreserved, sub-delims, ':', and percent-encoded allowed"
                )
            }

            i += 1
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Userinfo: CustomStringConvertible {
    /// The userinfo's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Userinfo {
    /// The username portion (before the colon, if present)
    ///
    /// For "john:secret", returns "john"
    /// For "john", returns "john"
    public var user: String {
        if let colonIndex = rawValue.firstIndex(of: ":") {
            return String(rawValue[..<colonIndex])
        }
        return rawValue
    }

    /// The password portion (after the colon, if present)
    ///
    /// For "john:secret", returns "secret"
    /// For "john", returns nil
    ///
    /// - Warning: Passwords in URIs are insecure and deprecated by RFC 3986
    public var password: String? {
        guard let colonIndex = rawValue.firstIndex(of: ":") else {
            return nil
        }
        let afterColon = rawValue.index(after: colonIndex)
        return afterColon < rawValue.endIndex ? String(rawValue[afterColon...]) : nil
    }
}

// MARK: - Codable

extension RFC_3986.URI.Userinfo {
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

public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

// MARK: - URI Scheme

extension RFC_3986.URI {
    /// URI scheme component per RFC 3986 Section 3.1
    ///
    /// Schemes consist of a sequence of characters beginning with a letter and followed
    /// by any combination of letters, digits, plus (+), period (.), or hyphen (-).
    ///
    /// Scheme names are case-insensitive and normalized to lowercase per RFC 3986.
    ///
    /// ## Example
    /// ```swift
    /// let scheme = try RFC_3986.URI.Scheme("https")
    /// print(scheme.value) // "https"
    ///
    /// // Case normalization
    /// let normalized = try RFC_3986.URI.Scheme("HTTPS")
    /// print(normalized.value) // "https"
    ///
    /// // Invalid scheme
    /// try RFC_3986.URI.Scheme("123invalid") // throws error
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    /// ```
    public struct Scheme: Sendable, Equatable, Hashable, Codable {
        /// RawValue type for RawRepresentable conformance
        public typealias RawValue = String

        /// The scheme value (normalized to lowercase)
        public let rawValue: String

        /// Creates a scheme WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw scheme value (unchecked)
        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue.lowercased()
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Scheme: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {
    /// Creates a scheme by validating `rawValue`, or `nil` if it is not a valid RFC 3986 scheme.
    ///
    /// Re-provides the `Swift.RawRepresentable` requirement (previously inherited
    /// from the retired combined ASCII serializable protocol).
    public init?(rawValue: String) {
        try? self.init(rawValue)
    }

    /// Serializes `value` as ASCII bytes derived from its `String` `rawValue`.
    ///
    /// Conformer-declared `ASCII.Serializable` witness: re-homes the operational
    /// tier onto this type's own ASCII verb, replacing the transitional default.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in value.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    /// Serializes `value` as ASCII bytes into `buffer`.
    ///
    /// Explicit `Binary.Serializable` witness: disambiguates the two
    /// constraint-incomparable `serialize(_:into:)` defaults (the RawRepresentable
    /// default vs the W0 ASCII bridge) — a conformer-declared member out-ranks both.
    /// The bytes derive from the free `[ASCII.Code]` serializer supplied by the
    /// `String`-RawRepresentable default (`.serialized`).
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: value.serialized)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Scheme: CustomStringConvertible {
    /// The scheme's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

// MARK: - Parseable

extension RFC_3986.URI.Scheme: ASCII.Parseable {
    /// Creates a scheme by validating `string`'s UTF-8 bytes as ASCII.
    ///
    /// Re-provides the string convenience initializer (previously inherited from
    /// the retired combined ASCII serializable protocol, Void context).
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses scheme from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 schemes are ASCII-only.
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Scheme (structured data)
    ///
    /// String-based parsing is derived as composition:
    /// ```
    /// String → [Byte] (UTF-8 bytes) → Scheme
    /// ```
    ///
    /// ## RFC 3986 Section 3.1
    ///
    /// ```
    /// scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the scheme
    /// - Throws: `RFC_3986.URI.Scheme.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard let firstByte = bytes.first else {
            throw Error.empty
        }

        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly (RFC 3986 scheme grammar is strict ASCII).
        // Non-ASCII bytes fail with `invalidStart` / `invalidCharacter` carrying the offending Byte.
        let firstCode: ASCII.Code
        do {
            firstCode = try ASCII.Code(firstByte)
        } catch {
            switch error {
            case .notASCII(let badByte):
                throw Error.invalidStart(String(decoding: bytes, as: UTF8.self), byte: badByte)
            }
        }
        guard firstCode.isLetter else {
            throw Error.invalidStart(String(decoding: bytes, as: UTF8.self), byte: firstCode.byte)
        }

        for byte in bytes.dropFirst() {
            let code: ASCII.Code
            do {
                code = try ASCII.Code(byte)
            } catch {
                switch error {
                case .notASCII(let badByte):
                    throw Error.invalidCharacter(
                        String(decoding: bytes, as: UTF8.self),
                        byte: badByte,
                        reason: "Only letters, digits, +, -, . allowed"
                    )
                }
            }
            let valid =
                code.isLetter
                || code.isDigit
                || code == ASCII.Code.plusSign
                || code == ASCII.Code.hyphen
                || code == ASCII.Code.period
            guard valid else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte,
                    reason: "Only letters, digits, +, -, . allowed"
                )
            }
        }

        // Normalize to lowercase per RFC 3986 Section 6.2.2.1
        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

// MARK: - Common Schemes

extension RFC_3986.URI.Scheme {
    /// HTTP scheme (http)
    public static let http = Self(__unchecked: (), rawValue: "http")

    /// HTTPS scheme (https)
    public static let https = Self(__unchecked: (), rawValue: "https")

    /// FTP scheme (ftp)
    public static let ftp = Self(__unchecked: (), rawValue: "ftp")

    /// FTPS scheme (ftps)
    public static let ftps = Self(__unchecked: (), rawValue: "ftps")

    /// File scheme (file)
    public static let file = Self(__unchecked: (), rawValue: "file")

    /// WebSocket scheme (ws)
    public static let ws = Self(__unchecked: (), rawValue: "ws")

    /// WebSocket Secure scheme (wss)
    public static let wss = Self(__unchecked: (), rawValue: "wss")

    /// Mailto scheme (mailto)
    public static let mailto = Self(__unchecked: (), rawValue: "mailto")

    /// Data scheme (data)
    public static let data = Self(__unchecked: (), rawValue: "data")
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Scheme {
    /// The scheme value (alias for rawValue for backward compatibility)
    public var value: String { rawValue }

    /// Returns true if this is a secure scheme (https, wss, ftps)
    public var isSecure: Bool {
        switch rawValue {
        case "https", "wss", "ftps":
            return true
        default:
            return false
        }
    }

    /// Returns true if this is an HTTP-family scheme (http, https)
    public var isHTTP: Bool {
        rawValue == "http" || rawValue == "https"
    }

    /// Returns the default port for this scheme, if any
    public var defaultPort: UInt16? {
        switch rawValue {
        case "http": return 80
        case "https": return 443
        case "ftp": return 21
        case "ftps": return 990
        case "ws": return 80
        case "wss": return 443
        default: return nil
        }
    }
}

// MARK: - Codable

extension RFC_3986.URI.Scheme {
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

// MARK: - Comparable

extension RFC_3986.URI.Scheme: Comparable {
    public static func < (lhs: RFC_3986.URI.Scheme, rhs: RFC_3986.URI.Scheme) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

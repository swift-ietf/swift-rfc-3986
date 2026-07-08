public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

// MARK: - URI Fragment

extension RFC_3986.URI {
    /// URI fragment component per RFC 3986 Section 3.5
    ///
    /// The fragment identifier component allows indirect identification of a secondary resource
    /// by reference to a primary resource and additional identifying information.
    ///
    /// Fragments are client-side only and are not sent to the server in HTTP requests.
    /// They are separated from the rest of the URI before dereferencing.
    ///
    /// ## Example
    /// ```swift
    /// // Create from string
    /// let fragment = try RFC_3986.URI.Fragment("section-1")
    /// print(fragment.value) // "section-1"
    ///
    /// // Use in URI
    /// let uri = try RFC_3986.URI("https://example.com/page#section-1")
    /// print(uri.fragment?.value) // "section-1"
    ///
    /// // Common patterns
    /// let heading = try RFC_3986.URI.Fragment("heading-intro")
    /// let anchor = try RFC_3986.URI.Fragment("top")
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// fragment = *( pchar / "/" / "?" )
    /// ```
    ///
    /// Per RFC 3986 Section 3.5:
    /// > The fragment identifier component allows indirect identification of a
    /// > secondary resource by reference to a primary resource and additional
    /// > identifying information. [...] The semantics of a fragment identifier
    /// > are defined by the set of representations that might result from a
    /// > retrieval action on the primary resource.
    public struct Fragment: Sendable, Equatable, Hashable, Codable {
        /// The fragment value
        public let rawValue: String

        /// Creates a fragment WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw fragment value (unchecked)
        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - RawValue

extension RFC_3986.URI.Fragment {
    /// RawValue type for RawRepresentable conformance
    public typealias RawValue = String
}

// MARK: - Serializable

extension RFC_3986.URI.Fragment: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {
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

    /// [FAM-012] binary sibling: an independent body re-emitting the fragment's
    /// own `rawValue` storage directly into the `Byte` domain — not a byte-detour
    /// through the ASCII verb. Byte-equivalent to the ASCII verb (a fragment is
    /// ASCII text); the `ascii.map(\.byte) == wire` equivalence test guards the
    /// two bodies against drift.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        for byte in value.rawValue.utf8 { buffer.append(Byte(byte)) }
    }
}

// MARK: - Parseable

extension RFC_3986.URI.Fragment: ASCII.Parseable {
    /// Re-provides the string convenience initializer (previously inherited from
    /// the retired combined ASCII serializable protocol, Void context).
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses fragment from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 fragments follow the pattern: *( pchar / "/" / "?" )
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Fragment (structured data)
    ///
    /// ## RFC 3986 Section 3.5
    ///
    /// ```
    /// fragment = *( pchar / "/" / "?" )
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the fragment
    /// - Throws: `RFC_3986.URI.Fragment.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        // Fragment can be empty per RFC 3986
        // Type-up: lift each byte to ASCII.Code (RFC 3986 fragment grammar is strict ASCII).
        // Non-ASCII bytes fail with `invalidCharacter` carrying the offending Byte.
        for byte in bytes {
            let code: ASCII.Code
            do throws(ASCII.Code.Error) {
                code = try ASCII.Code(byte)
            } catch {
                switch error {
                case .notASCII(let badByte):
                    throw Error.invalidCharacter(
                        String(decoding: bytes, as: UTF8.self),
                        byte: badByte,
                        reason: "non-ASCII byte in fragment"
                    )
                }
            }

            // Fragments cannot contain '#'
            if code == ASCII.Code.numberSign {
                throw Error.containsHash(String(decoding: bytes, as: UTF8.self))
            }

            // Check for newlines
            if code == ASCII.Code.lf || code == ASCII.Code.cr {
                throw Error.containsNewline(String(decoding: bytes, as: UTF8.self))
            }
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Fragment: CustomStringConvertible {
    /// The fragment's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Fragment {
    /// The fragment value (alias for rawValue for backward compatibility)
    public var value: String { rawValue }

    /// The string representation of the fragment
    ///
    /// Returns the fragment value (without leading "#").
    public var string: String {
        rawValue
    }

    /// Returns true if the fragment is empty
    public var isEmpty: Bool {
        rawValue.isEmpty
    }
}

// MARK: - Codable

extension RFC_3986.URI.Fragment {
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

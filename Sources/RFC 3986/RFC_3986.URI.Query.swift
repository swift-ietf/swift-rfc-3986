public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

// MARK: - URI RFC_3986.URI.Query

extension RFC_3986.URI {
    /// URI query component per RFC 3986 Section 3.4
    ///
    /// The query component contains non-hierarchical data that, along with data in the path component,
    /// serves to identify a resource within the scope of the URI's scheme and authority.
    ///
    /// RFC_3986.URI.Query parameters are case-sensitive and order-preserving. Multiple parameters with the same
    /// key are allowed (e.g., "tag=swift&tag=ios").
    ///
    /// ## Example
    /// ```swift
    /// // Create from parameters
    /// let query = try RFC_3986.URI.Query([
    ///     ("page", "1"),
    ///     ("limit", "20"),
    ///     ("sort", "name")
    /// ])
    /// print(query.string) // "page=1&limit=20&sort=name"
    ///
    /// // Access parameters
    /// let pages = query["page"] // ["1"]
    ///
    /// // Multiple values for same key
    /// let tags = try RFC_3986.URI.Query([
    ///     ("tag", "swift"),
    ///     ("tag", "ios")
    /// ])
    /// print(tags["tag"]) // ["swift", "ios"]
    ///
    /// // Parse from string
    /// let parsed = try RFC_3986.URI.Query("search=test&category=docs")
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// query = *( pchar / "/" / "?" )
    /// ```
    public struct Query: Sendable, Codable, Hashable, Equatable {
        /// RawValue type for RawRepresentable conformance
        public typealias RawValue = String

        /// The raw query string
        public let rawValue: String

        /// The query parameters as an array of key-value pairs
        ///
        /// Uses an array to preserve order and allow duplicate keys.
        /// Values can be nil to support keys without values (e.g., "flag" in "?flag&other=value")
        public let parameters: [(key: String, value: String?)]

        /// Creates a query WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - rawValue: The raw query value (unchecked)
        ///   - parameters: The parsed parameters (unchecked)
        init(
            __unchecked _: Void,
            rawValue: String,
            parameters: [(key: String, value: String?)]
        ) {
            self.rawValue = rawValue
            self.parameters = parameters
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Query: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {
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

    /// [FAM-012] binary sibling: an independent body re-emitting the query's own
    /// `rawValue` storage directly into the `Byte` domain — not a byte-detour
    /// through the ASCII verb. Byte-equivalent to the ASCII verb (a query is
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

extension RFC_3986.URI.Query: ASCII.Parseable {
    /// Re-provides the string convenience initializer (previously inherited from
    /// the retired combined ASCII serializable protocol, Void context).
    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    /// Parses query from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 queries follow the pattern: *( pchar / "/" / "?" )
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Query (structured data)
    ///
    /// ## RFC 3986 Section 3.4
    ///
    /// ```
    /// query = *( pchar / "/" / "?" )
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the query
    /// - Throws: `RFC_3986.URI.Query.Error` if the bytes are malformed
    public init<Bytes: Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        // Empty query is allowed
        if bytes.isEmpty {
            self.init(__unchecked: (), rawValue: "", parameters: [])
            return
        }

        // Type-up: lift to ASCII.Code at the entry boundary so the body works
        // against ASCII.Code constants directly (RFC 3986 query grammar is strict ASCII).
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
                    reason: "non-ASCII byte in query"
                )
            }
        }

        // Validate query characters at byte level
        var i = 0
        while i < arr.count {
            let code = arr[i]

            // Check for percent-encoding
            if code == ASCII.Code.percentSign {
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

                i = next2 + 1
                continue
            }

            // Check for newlines (invalid in queries)
            if code == ASCII.Code.lf || code == ASCII.Code.cr {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte,
                    reason: "Query cannot contain newlines"
                )
            }

            // Check for hash (invalid in queries - separates fragment)
            if code == ASCII.Code.numberSign {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte,
                    reason: "Query cannot contain '#' (use for fragment instead)"
                )
            }

            i += 1
        }

        let queryString = String(decoding: bytes, as: UTF8.self)

        // Parse parameters by scanning for '&' and '=' at byte level
        var parameters: [(String, String?)] = []
        var pairStart = 0

        func parsePair(_ lo: Int, _ hi: Int) throws(Error) {
            // Find '=' within this pair
            var eqIdx: Int? = nil
            for j in lo..<hi where arr[j] == ASCII.Code.equalsSign {
                eqIdx = j
                break
            }

            if let eq = eqIdx {
                let key = String(decoding: arr[lo..<eq], as: UTF8.self)
                guard !key.isEmpty else { throw Error.emptyKey }
                let value = String(decoding: arr[(eq &+ 1)..<hi], as: UTF8.self)
                parameters.append((key, value))
            } else {
                let key = String(decoding: arr[lo..<hi], as: UTF8.self)
                guard !key.isEmpty else { throw Error.emptyKey }
                parameters.append((key, nil))
            }
        }

        for idx in 0..<arr.count {
            if arr[idx] == ASCII.Code.ampersand {
                try parsePair(pairStart, idx)
                pairStart = idx &+ 1
            }
        }
        try parsePair(pairStart, arr.count)

        self.init(__unchecked: (), rawValue: queryString, parameters: parameters)
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Query: CustomStringConvertible {
    /// The query's ASCII serialization decoded as a `String`.
    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

// MARK: - Public Initializers

extension RFC_3986.URI.Query {
    /// The query parameters as an array of key-value pairs
    ///
    /// Uses an array to preserve order and allow duplicate keys.
    /// Values can be nil to support keys without values (e.g., "flag" in "?flag&other=value")
    private var _legacyParameters: [(key: String, value: String?)] { parameters }

    /// Creates a query from an array of parameters
    ///
    /// - Parameter parameters: The query parameters
    /// - Throws: `RFC_3986.URI.Query.Error` if parameters contain invalid characters
    public init(_ parameters: [(String, String?)] = []) throws(Error) {
        // Build query string from parameters
        let queryString = parameters.map { key, value in
            if let value = value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")

        // Use byte parser for validation
        try self.init(ascii: Array<Byte>(queryString.utf8))
    }

    /// Creates a query without validation
    ///
    /// This is an internal optimization for static constants and validated values.
    ///
    /// - Parameter parameters: The query parameters (must be valid, not validated)
    /// - Warning: This skips validation. For public use, use `try!` with
    ///   the throwing initializer to make the risk explicit.
    internal init(unchecked parameters: [(String, String?)]) {
        let queryString = parameters.map { key, value in
            if let value = value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")
        self.init(__unchecked: (), rawValue: queryString, parameters: parameters)
    }

    /// The string representation of the query
    ///
    /// Returns the query in the form "key1=value1&key2=value2" (without leading "?").
    /// Keys without values are rendered as just the key name.
    public var string: String {
        parameters.map { key, value in
            if let value = value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")
    }

    /// Returns true if the query has no parameters
    public var isEmpty: Bool {
        parameters.isEmpty
    }

    /// The number of parameters
    public var count: Int {
        parameters.count
    }

    /// Gets all values for a given key
    ///
    /// - Parameter key: The parameter key to look up
    /// - Returns: An array of values for that key (may be empty)
    public subscript(key: String) -> [String?] {
        parameters.filter { $0.key == key }.map { $0.value }
    }

    /// Gets the first value for a given key
    ///
    /// - Parameter key: The parameter key to look up
    /// - Returns: The first value for that key, or nil if not found
    public func first(for key: some StringProtocol) -> String? {
        parameters.first { $0.key == key }?.value ?? nil
    }

    /// Adds a parameter to the query
    ///
    /// - Parameters:
    ///   - key: The parameter key
    ///   - value: The parameter value (nil for keys without values)
    /// - Returns: A new query with the parameter added
    /// - Throws: `RFC_3986.Error.invalidComponent` if the parameter is invalid
    public func appending(
        key: some StringProtocol,
        value: (some StringProtocol)?
    ) throws(Error) -> RFC_3986.URI.Query {
        var newParameters = parameters
        newParameters.append((String(key), value.map { String($0) }))
        return try RFC_3986.URI.Query(newParameters)
    }

    /// Returns a new query with all parameters for a given key removed
    ///
    /// - Parameter key: The parameter key to remove
    /// - Returns: A new query without parameters matching the key
    public func removing(key: some StringProtocol) -> RFC_3986.URI.Query {
        let filtered = parameters.filter { $0.key != key }
        return RFC_3986.URI.Query(unchecked: filtered)
    }

    /// All unique keys in the query
    public var keys: Set<String> {
        Set(parameters.map { $0.key })
    }
}

// MARK: - Collection

extension RFC_3986.URI.Query: Collection {
    public typealias Index = Array<(key: String, value: String?)>.Index
    public typealias Element = (key: String, value: String?)

    public var startIndex: Index {
        parameters.startIndex
    }

    public var endIndex: Index {
        parameters.endIndex
    }

    public subscript(position: Index) -> Element {
        parameters[position]
    }

    public func index(after i: Index) -> Index {
        parameters.index(after: i)
    }
}

// MARK: - ExpressibleByArrayLiteral

extension RFC_3986.URI.Query: ExpressibleByArrayLiteral {
    /// Creates a query from an array literal of key-value tuples
    ///
    /// Example:
    /// ```swift
    /// let query: RFC_3986.URI.Query = [("page", "1"), ("limit", "20")]
    /// ```
    public init(arrayLiteral elements: (String, String?)...) {
        self.init(unchecked: elements)
    }
}

// MARK: - ExpressibleByDictionaryLiteral

extension RFC_3986.URI.Query: ExpressibleByDictionaryLiteral {
    /// Creates a query from a dictionary literal
    ///
    /// Example:
    /// ```swift
    /// let query: RFC_3986.URI.Query = ["page": "1", "limit": "20"]
    /// ```
    ///
    /// - Note: Dictionary literals don't preserve order or allow duplicate keys.
    ///   Use array literal syntax for those cases.
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(unchecked: elements.map { ($0, $1 as String?) })
    }
}

// MARK: - Hashable

extension RFC_3986.URI.Query {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue == rhs
    }
}

// MARK: - Codable

extension RFC_3986.URI.Query {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        do {
            try self.init(string)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid query: \(error)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

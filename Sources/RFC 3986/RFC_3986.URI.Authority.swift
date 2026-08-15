public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

// MARK: - URI Authority

extension RFC_3986.URI {
    /// URI authority component per RFC 3986 Section 3.2
    ///
    /// The authority component is preceded by a double slash ("//") and is terminated by
    /// the next slash ("/"), question mark ("?"), or number sign ("#") character, or by
    /// the end of the URI.
    ///
    /// ## Example
    /// ```swift
    /// // Authority with host only
    /// let simple = RFC_3986.URI.Authority(
    ///     host: try .init("example.com")
    /// )
    ///
    /// // Authority with host and port
    /// let withPort = RFC_3986.URI.Authority(
    ///     host: try .init("api.example.com"),
    ///     port: 8080
    /// )
    ///
    /// // Authority with userinfo, host, and port
    /// let full = RFC_3986.URI.Authority(
    ///     userinfo: "user:password",
    ///     host: try .init("ftp.example.com"),
    ///     port: 21
    /// )
    /// ```
    ///
    /// ## RFC 3986 Reference
    /// ```
    /// authority = [ userinfo "@" ] host [ ":" port ]
    /// userinfo = *( unreserved / pct-encoded / sub-delims / ":" )
    /// ```
    public struct Authority: Sendable, Equatable, Hashable {
        /// User information (username:password or similar)
        ///
        /// The use of userinfo in URIs is deprecated for security reasons.
        /// Per RFC 3986, applications should not render userinfo subcomponents
        /// unless the data is masked.
        @available(*, deprecated, message: "deprecated for security reasons")
        public let userinfo: RFC_3986.URI.Userinfo?

        /// The host component (domain, IPv4, or IPv6)
        public let host: RFC_3986.URI.Host

        /// The port number
        public let port: RFC_3986.URI.Port?

        /// Creates an authority WITHOUT validation
        ///
        /// **Warning**: Bypasses RFC 3986 validation.
        /// Only use with compile-time constants or pre-validated values.
        ///
        /// - Parameters:
        ///   - unchecked: Void parameter to prevent accidental use
        ///   - userinfo: Optional user information
        ///   - host: The host component
        ///   - port: Optional port number
        init(
            __unchecked _: Void,
            userinfo: RFC_3986.URI.Userinfo?,
            host: RFC_3986.URI.Host,
            port: RFC_3986.URI.Port?
        ) {
            self.userinfo = userinfo
            self.host = host
            self.port = port
        }

        /// Creates an authority component
        ///
        /// - Parameters:
        ///   - userinfo: Optional user information
        ///   - host: The host component
        ///   - port: Optional port number
        public init(
            userinfo: RFC_3986.URI.Userinfo? = nil,
            host: RFC_3986.URI.Host,
            port: RFC_3986.URI.Port? = nil
        ) {
            self.init(__unchecked: (), userinfo: userinfo, host: host, port: port)
        }
    }
}

// MARK: - Serializable

extension RFC_3986.URI.Authority: ASCII.Serializable, Binary.Serializable {
    /// [FAM-012] text sibling (`ASCII.Code`) — RFC 3986 §3.2
    /// `[ userinfo "@" ] host [ ":" port ]`. Clause-9: each sub-component composes
    /// its own `ASCII.Serializable` verb directly into the sink.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ authority: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        if let userinfo = authority.userinfo {
            RFC_3986.URI.Userinfo.serialize(userinfo, into: &buffer)
            buffer.append(ASCII.Code.commercialAt)
        }

        RFC_3986.URI.Host.serialize(authority.host, into: &buffer)

        if let port = authority.port {
            buffer.append(ASCII.Code.colon)
            RFC_3986.URI.Port.serialize(port, into: &buffer)
        }
    }

    /// [FAM-012] binary sibling (`Byte`) — the authority text as wire bytes.
    /// Clause-9: each sub-component composes its own `Binary.Serializable` verb
    /// (each of which is itself text-as-bytes) directly into the sink. The
    /// `ascii.map(\.byte) == wire` equivalence test guards the two bodies.
    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ authority: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        if let userinfo = authority.userinfo {
            RFC_3986.URI.Userinfo.serialize(userinfo, into: &buffer)
            buffer.append(ASCII.Code.commercialAt.byte)
        }

        RFC_3986.URI.Host.serialize(authority.host, into: &buffer)

        if let port = authority.port {
            buffer.append(ASCII.Code.colon.byte)
            RFC_3986.URI.Port.serialize(port, into: &buffer)
        }
    }
}

// MARK: - Parseable

extension RFC_3986.URI.Authority: ASCII.Parseable {
    /// Parses authority from ASCII bytes (CANONICAL PRIMITIVE)
    ///
    /// This is the primitive parser that works at the byte level.
    /// RFC 3986 authority follows the pattern: [ userinfo "@" ] host [ ":" port ]
    ///
    /// ## Category Theory
    ///
    /// This is the fundamental parsing transformation:
    /// - **Domain**: [Byte] (ASCII bytes)
    /// - **Codomain**: RFC_3986.URI.Authority (structured data)
    ///
    /// ## RFC 3986 Section 3.2
    ///
    /// ```
    /// authority = [ userinfo "@" ] host [ ":" port ]
    /// ```
    ///
    /// - Parameter bytes: The ASCII byte representation of the authority
    /// - Throws: `RFC_3986.URI.Authority.Error` if the bytes are malformed
    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        let string = String(decoding: bytes, as: UTF8.self)
        var remaining = string

        // Extract userinfo if present (before @)
        let userinfo: RFC_3986.URI.Userinfo?
        if let atIndex = remaining.firstIndex(of: "@") {
            let userinfoString = String(remaining[..<atIndex])
            do throws(RFC_3986.URI.Userinfo.Error) {
                userinfo = try RFC_3986.URI.Userinfo(userinfoString)
            } catch {
                throw Error.invalidUserinfo(userinfoString, underlying: error)
            }
            remaining = String(remaining[remaining.index(after: atIndex)...])
        } else {
            userinfo = nil
        }

        // Extract port if present (after last :, but not in IPv6 brackets)
        let port: RFC_3986.URI.Port?
        let host: RFC_3986.URI.Host

        // Check if this is an IPv6 address (starts with [)
        if remaining.hasPrefix("[") {
            // IPv6 - find the closing bracket
            guard let closeBracket = remaining.firstIndex(of: "]") else {
                throw Error.unterminatedIPv6(string)
            }

            let hostString = String(remaining[...closeBracket])
            remaining = String(remaining[remaining.index(after: closeBracket)...])

            // Check for port after ]
            if remaining.hasPrefix(":") {
                let portString = String(remaining.dropFirst())
                guard let portValue = RFC_3986.URI.Port(portString) else {
                    throw Error.invalidPort(portString)
                }
                port = portValue
            } else if !remaining.isEmpty {
                throw Error.invalidCharactersAfterIPv6(remaining)
            } else {
                port = nil
            }

            do throws(RFC_3986.URI.Host.Error) {
                host = try RFC_3986.URI.Host(hostString)
            } catch {
                throw Error.invalidHost(hostString, underlying: error)
            }
        } else {
            // IPv4 or registered name - port is after last :
            if let colonIndex = remaining.lastIndex(of: ":") {
                let hostString = String(remaining[..<colonIndex])
                let portString = String(remaining[remaining.index(after: colonIndex)...])

                guard let portValue = RFC_3986.URI.Port(portString) else {
                    throw Error.invalidPort(portString)
                }

                do throws(RFC_3986.URI.Host.Error) {
                    host = try RFC_3986.URI.Host(hostString)
                } catch {
                    throw Error.invalidHost(hostString, underlying: error)
                }
                port = portValue
            } else {
                do throws(RFC_3986.URI.Host.Error) {
                    host = try RFC_3986.URI.Host(remaining)
                } catch {
                    throw Error.invalidHost(remaining, underlying: error)
                }
                port = nil
            }
        }

        self.init(__unchecked: (), userinfo: userinfo, host: host, port: port)
    }
}

// MARK: - Initialization

extension RFC_3986.URI.Authority {
    /// Creates an authority from its string representation
    ///
    /// - Parameter string: The authority string (e.g., "user@example.com:8080")
    /// - Throws: `RFC_3986.Error` if the authority is invalid
    ///
    /// This parses an authority string in the form:
    /// `[userinfo@]host[:port]`
    public init(_ string: some StringProtocol) throws(Error) {
        var remaining = String(string)

        // Extract userinfo if present (before @)
        let userinfo: RFC_3986.URI.Userinfo?
        if let atIndex = remaining.firstIndex(of: "@") {
            let userinfoString = String(remaining[..<atIndex])
            do throws(RFC_3986.URI.Userinfo.Error) {
                userinfo = try RFC_3986.URI.Userinfo(userinfoString)
            } catch {
                throw Error.invalidUserinfo(userinfoString, underlying: error)
            }
            remaining = String(remaining[remaining.index(after: atIndex)...])
        } else {
            userinfo = nil
        }

        // Extract port if present (after last :, but not in IPv6 brackets)
        let port: RFC_3986.URI.Port?
        let host: RFC_3986.URI.Host

        // Check if this is an IPv6 address (starts with [)
        if remaining.hasPrefix("[") {
            // IPv6 - find the closing bracket
            guard let closeBracket = remaining.firstIndex(of: "]") else {
                throw Error.unterminatedIPv6(String(string))
            }

            let hostString = String(remaining[...closeBracket])
            remaining = String(remaining[remaining.index(after: closeBracket)...])

            // Check for port after ]
            if remaining.hasPrefix(":") {
                let portString = String(remaining.dropFirst())
                guard let portValue = RFC_3986.URI.Port(portString) else {
                    throw Error.invalidPort(portString)
                }
                port = portValue
            } else if !remaining.isEmpty {
                throw Error.invalidCharactersAfterIPv6(remaining)
            } else {
                port = nil
            }

            do throws(RFC_3986.URI.Host.Error) {
                host = try RFC_3986.URI.Host(hostString)
            } catch {
                throw Error.invalidHost(hostString, underlying: error)
            }
        } else {
            // IPv4 or registered name - port is after last :
            if let colonIndex = remaining.lastIndex(of: ":") {
                let hostString = String(remaining[..<colonIndex])
                let portString = String(remaining[remaining.index(after: colonIndex)...])

                guard let portValue = RFC_3986.URI.Port(portString) else {
                    throw Error.invalidPort(portString)
                }

                do throws(RFC_3986.URI.Host.Error) {
                    host = try RFC_3986.URI.Host(hostString)
                } catch {
                    throw Error.invalidHost(hostString, underlying: error)
                }
                port = portValue
            } else {
                do throws(RFC_3986.URI.Host.Error) {
                    host = try RFC_3986.URI.Host(remaining)
                } catch {
                    throw Error.invalidHost(remaining, underlying: error)
                }
                port = nil
            }
        }

        self.init(userinfo: userinfo, host: host, port: port)
    }
}

// MARK: - Convenience Properties

extension RFC_3986.URI.Authority {
    /// The string representation of the authority
    ///
    /// Returns the authority in the form: `[userinfo@]host[:port]`
    public var rawValue: String {
        var result = ""

        if let userinfo {
            result += "\(userinfo.rawValue)@"
        }

        result += host.rawValue

        if let port {
            result += ":\(port.value)"
        }

        return result
    }
}

// MARK: - CustomStringConvertible

extension RFC_3986.URI.Authority: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

// MARK: - Codable

extension RFC_3986.URI.Authority: Codable {
    // reason: Decodable's `init(from:) throws` requirement is fixed by the stdlib protocol — `any Decoder` and untyped `throws` cannot be replaced with a generic constraint or typed throws without breaking Codable conformance.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    // reason: Encodable's `encode(to:) throws` requirement is fixed by the stdlib protocol — `any Encoder` and untyped `throws` cannot be replaced with a generic constraint or typed throws without breaking Codable conformance.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Error

extension RFC_3986.URI.Authority {
    /// Errors that can occur when parsing an authority component
    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {
        // reason: boxes whichever concrete error the userinfo validator produced; a generic parameter can't unify with `invalidHost`'s independently-typed underlying error on the same enum.
        // The block form is used here instead of `disable:next` because this declaration
        // carries a doc comment: a directive between the doc comment and the declaration
        // trips `orphaned_doc_comment`.
        // swiftlint:disable no_any_protocol_existential
        /// The userinfo component is invalid
        case invalidUserinfo(String, underlying: any Swift.Error)
        // swiftlint:enable no_any_protocol_existential

        // reason: boxes whichever concrete error the host validator produced; a generic parameter can't unify with `invalidUserinfo`'s independently-typed underlying error on the same enum.
        // swiftlint:disable no_any_protocol_existential
        /// The host component is invalid
        case invalidHost(String, underlying: any Swift.Error)
        // swiftlint:enable no_any_protocol_existential

        /// The port component is invalid
        case invalidPort(String)

        /// IPv6 address is not terminated with ]
        case unterminatedIPv6(String)

        /// Invalid characters after IPv6 address
        case invalidCharactersAfterIPv6(String)
    }
}

extension RFC_3986.URI.Authority.Error {
    public var description: String {
        switch self {
        case .invalidUserinfo(let value, _):
            return "Invalid userinfo: '\(value)'"

        case .invalidHost(let value, _):
            return "Invalid host: '\(value)'"

        case .invalidPort(let value):
            return "Invalid port: '\(value)'"

        case .unterminatedIPv6(let value):
            return "Unterminated IPv6 address in: '\(value)'"

        case .invalidCharactersAfterIPv6(let value):
            return "Invalid characters after IPv6 address: '\(value)'"
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.invalidUserinfo(let l, _), .invalidUserinfo(let r, _)): l == r
        case (.invalidHost(let l, _), .invalidHost(let r, _)): l == r
        case (.invalidPort(let l), .invalidPort(let r)): l == r
        case (.unterminatedIPv6(let l), .unterminatedIPv6(let r)): l == r
        case (.invalidCharactersAfterIPv6(let l), .invalidCharactersAfterIPv6(let r)): l == r
        default: false
        }
    }
}

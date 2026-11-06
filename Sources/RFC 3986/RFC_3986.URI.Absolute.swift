extension RFC_3986.URI {

    /// RFC 3986 section 4.3's absolute-URI: a scheme and something after it, and no fragment.
    public struct Absolute: Hashable, Sendable {

        public let uri: RFC_3986.URI

        public init(_ uri: RFC_3986.URI) throws(RFC_3986.Error) {
            guard uri.scheme != nil else { throw .invalidURI("\(uri.value): an absolute URI has a scheme") }
            guard uri.fragment == nil else { throw .invalidURI("\(uri.value): an absolute URI has no fragment") }
            guard uri.host != nil || uri.path?.isEmpty == false else {
                throw .invalidURI("\(uri.value): an absolute URI has something after its scheme")
            }
            self.uri = uri
        }

        public init(_ value: some StringProtocol) throws(RFC_3986.Error) {
            try self.init(try RFC_3986.URI(value))
        }
    }
}

extension RFC_3986.URI.Absolute: CustomStringConvertible {

    public var description: String { uri.value }
}

extension RFC_3986.URI.Absolute: Codable {

    public init(from decoder: any Decoder) throws {
        try self.init(try decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(uri.value)
    }
}

public import Byte

extension RFC_3986.URI.Query {

    public enum Error: Swift.Error, Sendable, Equatable {

        case emptyKey

        case keyContainsNewline(_ key: String)

        case valueContainsNewline(_ key: String, value: String)

        case invalidCharacter(_ value: String, byte: Byte, reason: String)

        case invalidPercentEncoding(_ value: String, reason: String)
    }
}

extension RFC_3986.URI.Query.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .emptyKey:
            return "Query parameter key cannot be empty"

        case .keyContainsNewline(let key):
            return "Query parameter key '\(key)' contains newline"

        case .valueContainsNewline(let key, let value):
            return "Query parameter '\(key)' has value '\(value)' containing newline"

        case .invalidCharacter(let value, let byte, let reason):
            return "Query '\(value)' has invalid byte 0x\(String(byte.bitPattern, radix: 16)): \(reason)"

        case .invalidPercentEncoding(let value, let reason):
            return "Query '\(value)' has invalid percent-encoding: \(reason)"
        }
    }
}

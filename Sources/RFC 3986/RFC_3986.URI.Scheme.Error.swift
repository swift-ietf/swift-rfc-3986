public import ASCII_Serializer_Primitives

extension RFC_3986.URI.Scheme {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case invalidStart(_ value: String, byte: Byte)

        case invalidCharacter(_ value: String, byte: Byte, reason: String)
    }
}

extension RFC_3986.URI.Scheme.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Scheme cannot be empty"

        case .invalidStart(let value, let byte):
            return "Scheme '\(value)' must start with a letter, got 0x\(String(byte, radix: 16))"

        case .invalidCharacter(let value, let byte, let reason):
            return "Scheme '\(value)' has invalid byte 0x\(String(byte, radix: 16)): \(reason)"
        }
    }
}

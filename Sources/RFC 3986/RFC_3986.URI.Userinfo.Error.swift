public import ASCII_Serializer

extension RFC_3986.URI.Userinfo {

    public enum Error: Swift.Error, Sendable, Equatable {

        case invalidCharacter(_ value: String, byte: Byte, reason: String)

        case invalidPercentEncoding(_ value: String, reason: String)
    }
}

extension RFC_3986.URI.Userinfo.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidCharacter(let value, let byte, let reason):
            return "Userinfo '\(value)' has invalid byte 0x\(String(byte, radix: 16)): \(reason)"

        case .invalidPercentEncoding(let value, let reason):
            return "Userinfo '\(value)' has invalid percent-encoding: \(reason)"
        }
    }
}

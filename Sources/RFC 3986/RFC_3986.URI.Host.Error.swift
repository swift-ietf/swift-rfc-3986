public import ASCII_Serializer
import Byte

extension RFC_3986.URI.Host {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case invalidIPv6(_ value: String, reason: String)

        case invalidIPv4(_ value: String, reason: String)

        case invalidRegisteredName(_ value: String, reason: String)

        case invalidCharacter(_ value: String, byte: Byte, reason: String)
    }
}

extension RFC_3986.URI.Host.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Host cannot be empty"

        case .invalidIPv6(let value, let reason):
            return "Invalid IPv6 address '\(value)': \(reason)"

        case .invalidIPv4(let value, let reason):
            return "Invalid IPv4 address '\(value)': \(reason)"

        case .invalidRegisteredName(let value, let reason):
            return "Invalid registered name '\(value)': \(reason)"

        case .invalidCharacter(let value, let byte, let reason):
            return "Host '\(value)' has invalid byte 0x\(String(byte.bitPattern, radix: 16)): \(reason)"
        }
    }
}

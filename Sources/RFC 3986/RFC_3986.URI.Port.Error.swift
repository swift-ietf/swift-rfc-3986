public import ASCII_Serializer
import Byte

extension RFC_3986.URI.Port {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case invalidCharacter(_ value: String, byte: Byte)

        case overflow(_ value: String)
    }
}

extension RFC_3986.URI.Port.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Port cannot be empty"

        case .invalidCharacter(let value, let byte):
            return
                "Port '\(value)' contains invalid byte 0x\(String(byte.bitPattern, radix: 16)): only digits allowed"

        case .overflow(let value):
            return "Port '\(value)' overflows maximum value of 65535"
        }
    }
}

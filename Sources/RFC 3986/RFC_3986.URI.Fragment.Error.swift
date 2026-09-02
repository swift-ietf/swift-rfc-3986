public import ASCII_Serializer
import Byte

extension RFC_3986.URI.Fragment {

    public enum Error: Swift.Error, Sendable, Equatable {

        case containsHash(_ value: String)

        case containsNewline(_ value: String)

        case invalidCharacter(_ value: String, byte: Byte, reason: String)
    }
}

extension RFC_3986.URI.Fragment.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .containsHash(let value):
            return "Fragment '\(value)' cannot contain '#' character"

        case .containsNewline(let value):
            return "Fragment '\(value)' cannot contain newline characters"

        case .invalidCharacter(let value, let byte, let reason):
            return "Fragment '\(value)' has invalid byte 0x\(String(byte.bitPattern, radix: 16)): \(reason)"
        }
    }
}

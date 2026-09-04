public import Byte

extension RFC_3986.URI.Path {

    public enum Error: Swift.Error, Sendable, Equatable {

        case segmentContainsSeparator(_ segment: String)

        case segmentContainsWhitespace(_ segment: String)

        case invalidCharacter(_ value: String, byte: Byte, reason: String)

        case invalidPercentEncoding(_ value: String, reason: String)
    }
}

extension RFC_3986.URI.Path.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .segmentContainsSeparator(let segment):
            return "Path segment cannot contain '/': \(segment)"

        case .segmentContainsWhitespace(let segment):
            return "Path segment contains invalid whitespace: \(segment)"

        case .invalidCharacter(let value, let byte, let reason):
            return "Path '\(value)' has invalid byte 0x\(String(byte.bitPattern, radix: 16)): \(reason)"

        case .invalidPercentEncoding(let value, let reason):
            return "Path '\(value)' has invalid percent-encoding: \(reason)"
        }
    }
}

public import Byte
public import Cursor
public import Parser
import Checkpoint
import Iterator_Protocol

extension RFC_3986.URI.Scheme {

    public struct Parse<Input: Cursor.`Protocol`>: Sendable
    where Input.Element == Byte, Input.Failure == Never {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Scheme {

    public enum ParseFailure: Swift.Error, Sendable, Equatable {
        case expectedAlpha
    }
}

extension RFC_3986.URI.Scheme.Parse: Parser.`Protocol` {
    public typealias Output = [Byte]
    public typealias Failure = RFC_3986.URI.Scheme.ParseFailure
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> [Byte] {
        var checkpoint = input.checkpoint

        guard let first = input.next(), RFC_3986.Parse._isAlpha(first.bitPattern) else {
            input.seek(to: checkpoint)
            throw .expectedAlpha
        }

        var result: [Byte] = [first]
        checkpoint = input.checkpoint

        while let byte = input.next() {
            guard Self._isSchemeChar(byte.bitPattern) else {
                input.seek(to: checkpoint)
                break
            }
            result.append(byte)
            checkpoint = input.checkpoint
        }

        return result
    }

    @inlinable
    package static func _isSchemeChar(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x41...0x5A: true
        case 0x61...0x7A: true
        case 0x30...0x39: true
        case 0x2B: true
        case 0x2D: true
        case 0x2E: true
        default: false
        }
    }
}

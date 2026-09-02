public import Byte
public import Cursor
public import Parser
import Checkpoint
import Iterator_Protocol

extension RFC_3986.URI.Host {

    public struct Parse<Input: Cursor.`Protocol`>: Sendable
    where Input.Element == Byte, Input.Failure == Never {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Host {

    public enum ParseFailure: Swift.Error, Sendable, Equatable {
        case unterminatedIPLiteral
    }
}

extension RFC_3986.URI.Host.Parse: Parser.`Protocol` {
    public typealias Output = [Byte]
    public typealias Failure = RFC_3986.URI.Host.ParseFailure
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> [Byte] {
        let start = input.checkpoint

        guard let first = input.next() else { return [] }

        if first.bitPattern == 0x5B {
            var literal: [Byte] = [first]
            while let byte = input.next() {
                literal.append(byte)
                if byte.bitPattern == 0x5D { return literal }
            }
            input.seek(to: start)
            throw .unterminatedIPLiteral
        }

        guard RFC_3986.Parse._isRegNameChar(first.bitPattern) else {
            input.seek(to: start)
            return []
        }

        var result: [Byte] = [first]
        var checkpoint = input.checkpoint

        while let byte = input.next() {
            guard RFC_3986.Parse._isRegNameChar(byte.bitPattern) else {
                input.seek(to: checkpoint)
                break
            }
            result.append(byte)
            checkpoint = input.checkpoint
        }

        return result
    }
}

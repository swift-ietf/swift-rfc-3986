public import Byte
public import Cursor
public import Parser
import Checkpoint
import Iterator_Protocol

extension RFC_3986.URI.Query {

    public struct Parse<Input: Cursor.`Protocol`>: Sendable
    where Input.Element == Byte, Input.Failure == Never {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Query.Parse: Parser.`Protocol` {
    public typealias Output = [Byte]
    public typealias Failure = Never
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) -> [Byte] {
        var result: [Byte] = []
        var checkpoint = input.checkpoint

        while let byte = input.next() {
            let raw = byte.bitPattern
            guard raw != 0x23 else {
                input.seek(to: checkpoint)
                break
            }
            guard RFC_3986.Parse._isQueryOrFragmentChar(raw) else {
                input.seek(to: checkpoint)
                break
            }
            result.append(byte)
            checkpoint = input.checkpoint
        }

        return result
    }
}

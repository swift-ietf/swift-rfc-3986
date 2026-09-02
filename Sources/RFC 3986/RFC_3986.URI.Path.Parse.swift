public import Byte
public import Cursor
public import Parser
import Checkpoint
import Iterator_Protocol

extension RFC_3986.URI.Path {

    public struct Parse<Input: Cursor.`Protocol`>: Sendable
    where Input.Element == Byte, Input.Failure == Never {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Path.Parse: Parser.`Protocol` {
    public typealias Output = [Byte]
    public typealias Failure = Never
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) -> [Byte] {
        var result: [Byte] = []
        var checkpoint = input.checkpoint

        while let byte = input.next() {
            let raw = byte.bitPattern
            guard RFC_3986.Parse._isPchar(raw) || raw == 0x2F else {
                input.seek(to: checkpoint)
                break
            }
            result.append(byte)
            checkpoint = input.checkpoint
        }

        return result
    }
}

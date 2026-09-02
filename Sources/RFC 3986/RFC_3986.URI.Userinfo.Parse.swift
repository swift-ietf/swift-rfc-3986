public import Byte
public import Cursor
public import Parser
import Checkpoint
import Iterator_Protocol

extension RFC_3986.URI.Userinfo {

    public struct Parse<Input: Cursor.`Protocol`>: Sendable
    where Input.Element == Byte, Input.Failure == Never {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Userinfo.Parse: Parser.`Protocol` {
    public typealias Output = [Byte]
    public typealias Failure = Never
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) -> [Byte] {
        var result: [Byte] = []
        var checkpoint = input.checkpoint

        while let byte = input.next() {
            guard RFC_3986.Parse._isUserinfoChar(byte.bitPattern) else {
                input.seek(to: checkpoint)
                break
            }
            result.append(byte)
            checkpoint = input.checkpoint
        }

        return result
    }
}

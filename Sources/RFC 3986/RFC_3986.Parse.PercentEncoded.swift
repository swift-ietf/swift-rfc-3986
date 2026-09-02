public import ASCII
public import Byte
public import Cursor
public import Parser
import Checkpoint
import Iterator_Protocol

extension RFC_3986.Parse {

    public enum PercentEncoded {}
}

extension RFC_3986.Parse.PercentEncoded {

    public enum Failure: Swift.Error, Sendable, Equatable {
        case expectedPercent
        case expectedHexDigit
    }

    public struct Parse<Input: Cursor.`Protocol`>: Sendable
    where Input.Element == Byte, Input.Failure == Never {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.Parse.PercentEncoded.Parse: Parser.`Protocol` {
    public typealias Output = Byte
    public typealias Failure = RFC_3986.Parse.PercentEncoded.Failure
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Byte {
        let start = input.checkpoint

        guard let percent = input.next(), percent.bitPattern == 0x25 else {
            input.seek(to: start)
            throw .expectedPercent
        }

        guard
            let first = input.next(),
            let high = Self._hexValue(ASCII.Code(unchecked: first))
        else {
            input.seek(to: start)
            throw .expectedHexDigit
        }

        guard
            let second = input.next(),
            let low = Self._hexValue(ASCII.Code(unchecked: second))
        else {
            input.seek(to: start)
            throw .expectedHexDigit
        }

        return Byte(bitPattern: (high << 4) | low)
    }

    @inlinable
    package static func _hexValue(_ code: ASCII.Code) -> UInt8? {
        code.hexValue
    }
}

public import ASCII_Decimal_Parser
public import Byte
public import Cursor
public import Parser
import ASCII

extension RFC_3986.URI.Port {

    public struct Parse<Input: Cursor.`Protocol`>: Sendable
    where Input.Element == Byte, Input.Failure == Never {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Port {

    public enum ParseFailure: Swift.Error, Sendable, Equatable {
        case expectedDigit
        case overflow
    }
}

extension RFC_3986.URI.Port.Parse: Parser.`Protocol` {
    public typealias Output = UInt16
    public typealias Failure = RFC_3986.URI.Port.ParseFailure
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> UInt16 {
        do throws(ASCII.Decimal.Error) {
            return try ASCII.Decimal.Parser<Input, UInt16>().parse(&input)
        } catch {
            switch error {
            case .noDigits, .insufficientDigits, .invalidSign: throw .expectedDigit
            case .overflow: throw .overflow
            }
        }
    }
}

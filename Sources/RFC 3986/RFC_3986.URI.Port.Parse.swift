public import ASCII_Decimal_Parser_Primitives
import Byte_Primitives
import Parser_Primitives

extension RFC_3986.URI.Port {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
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

public import ASCII_Primitives
public import Parser_Primitives

extension RFC_3986.Parse {

    public enum PercentEncoded {}
}

extension RFC_3986.Parse.PercentEncoded {

    public enum Failure: Swift.Error, Sendable, Equatable {
        case expectedPercent
        case expectedHexDigit
    }

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.Parse.PercentEncoded.Parse: Parser.`Protocol` {
    public typealias Output = UInt8
    public typealias Failure = RFC_3986.Parse.PercentEncoded.Failure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> UInt8 {

        guard input.startIndex < input.endIndex, input[input.startIndex] == 0x25 else {
            throw .expectedPercent
        }
        input = input[input.index(after: input.startIndex)...]

        guard input.startIndex < input.endIndex else { throw .expectedHexDigit }
        guard let high = Self._hexValue(ASCII.Code(input[input.startIndex])) else {
            throw .expectedHexDigit
        }
        input = input[input.index(after: input.startIndex)...]

        guard input.startIndex < input.endIndex else { throw .expectedHexDigit }
        guard let low = Self._hexValue(ASCII.Code(input[input.startIndex])) else {
            throw .expectedHexDigit
        }
        input = input[input.index(after: input.startIndex)...]

        return (high << 4) | low
    }

    @inlinable
    package static func _hexValue(_ code: ASCII.Code) -> UInt8? {

        code.hexValue
    }
}

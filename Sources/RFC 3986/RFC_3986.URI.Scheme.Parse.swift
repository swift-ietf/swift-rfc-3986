public import Parser_Primitives

extension RFC_3986.URI.Scheme {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
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
    public typealias Output = Input
    public typealias Failure = RFC_3986.URI.Scheme.ParseFailure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Input {
        var index = input.startIndex

        guard index < input.endIndex else { throw .expectedAlpha }
        let first = input[index]
        guard (first >= 0x41 && first <= 0x5A) || (first >= 0x61 && first <= 0x7A) else {
            throw .expectedAlpha
        }
        input.formIndex(after: &index)

        while index < input.endIndex {
            let byte = input[index]
            guard Self._isSchemeChar(byte) else { break }
            input.formIndex(after: &index)
        }

        let result = input[input.startIndex..<index]
        input = input[index...]
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

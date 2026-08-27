public import Parser

extension RFC_3986.URI.Host {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
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
    public typealias Output = Input
    public typealias Failure = RFC_3986.URI.Host.ParseFailure

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Input {
        guard input.startIndex < input.endIndex else {
            return input[input.startIndex..<input.startIndex]
        }

        if input[input.startIndex] == 0x5B {

            var index = input.startIndex
            input.formIndex(after: &index)
            while index < input.endIndex {
                if input[index] == 0x5D {
                    input.formIndex(after: &index)
                    let result = input[input.startIndex..<index]
                    input = input[index...]
                    return result
                }
                input.formIndex(after: &index)
            }
            throw .unterminatedIPLiteral
        } else {

            var index = input.startIndex
            while index < input.endIndex {
                let byte = input[index]
                guard RFC_3986.Parse._isRegNameChar(byte) else { break }
                input.formIndex(after: &index)
            }
            let result = input[input.startIndex..<index]
            input = input[index...]
            return result
        }
    }
}

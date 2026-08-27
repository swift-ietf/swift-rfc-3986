public import Parser

extension RFC_3986.URI.Fragment {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Fragment.Parse: Parser.`Protocol` {
    public typealias Output = Input
    public typealias Failure = Never

    @inlinable
    public func parse(_ input: inout Input) -> Input {
        var index = input.startIndex
        while index < input.endIndex {
            let byte = input[index]
            guard RFC_3986.Parse._isQueryOrFragmentChar(byte) else { break }
            input.formIndex(after: &index)
        }
        let result = input[input.startIndex..<index]
        input = input[index...]
        return result
    }
}

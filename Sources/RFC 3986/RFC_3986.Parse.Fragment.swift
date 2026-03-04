//
//  RFC_3986.Parse.Fragment.swift
//  swift-rfc-3986
//
//  URI fragment: *( pchar / "/" / "?" )
//

public import Parser_Primitives

extension RFC_3986.Parse {
    /// Parses a URI fragment per RFC 3986 Section 3.5.
    ///
    /// `fragment = *( pchar / "/" / "?" )`
    ///
    /// Returns the raw byte slice (caller provides input after the `#` delimiter).
    public struct Fragment<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.Parse.Fragment: Parser.`Protocol` {
    public typealias ParseOutput = Input
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

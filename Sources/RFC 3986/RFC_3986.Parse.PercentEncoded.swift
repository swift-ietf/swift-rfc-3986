//
//  RFC_3986.Parse.PercentEncoded.swift
//  swift-rfc-3986
//
//  Percent-encoded triplet: "%" HEXDIG HEXDIG
//

public import Parser_Primitives

extension RFC_3986.Parse {
    /// Parses a percent-encoded triplet per RFC 3986 Section 2.1.
    ///
    /// `pct-encoded = "%" HEXDIG HEXDIG`
    ///
    /// Returns the decoded byte value (e.g., "%20" -> 0x20).
    public struct PercentEncoded<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.Parse.PercentEncoded {
    public enum Error: Swift.Error, Sendable, Equatable {
        case expectedPercent
        case expectedHexDigit
    }
}

extension RFC_3986.Parse.PercentEncoded: Parser.`Protocol` {
    public typealias ParseOutput = UInt8
    public typealias Failure = RFC_3986.Parse.PercentEncoded<Input>.Error

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> UInt8 {
        // Expect '%'
        guard input.startIndex < input.endIndex, input[input.startIndex] == 0x25 else {
            throw .expectedPercent
        }
        input = input[input.index(after: input.startIndex)...]

        // First hex digit
        guard input.startIndex < input.endIndex else { throw .expectedHexDigit }
        guard let high = Self._hexValue(input[input.startIndex]) else { throw .expectedHexDigit }
        input = input[input.index(after: input.startIndex)...]

        // Second hex digit
        guard input.startIndex < input.endIndex else { throw .expectedHexDigit }
        guard let low = Self._hexValue(input[input.startIndex]) else { throw .expectedHexDigit }
        input = input[input.index(after: input.startIndex)...]

        return (high << 4) | low
    }

    @inlinable
    static func _hexValue(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 0x30...0x39: byte &- 0x30
        case 0x41...0x46: byte &- 0x37
        case 0x61...0x66: byte &- 0x57
        default: nil
        }
    }
}

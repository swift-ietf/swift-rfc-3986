//
//  RFC_3986.Parse.PercentEncoded.swift
//  swift-rfc-3986
//
//  Percent-encoded triplet: "%" HEXDIG HEXDIG
//

public import Parser_Primitives
public import ASCII_Primitives

extension RFC_3986.Parse {
    /// Percent-encoded triplet namespace per RFC 3986 Section 2.1.
    ///
    /// `pct-encoded = "%" HEXDIG HEXDIG`
    ///
    /// A non-generic namespace owning the parser (``Parse``) and its
    /// error (``Error``). The parser is generic over its `Input`
    /// collection; the error is not, so it lives on the namespace rather
    /// than on the generic parser (see ``Error``).
    public enum PercentEncoded {}
}

extension RFC_3986.Parse.PercentEncoded {
    /// Failures from the percent-encoded triplet ``Parse`` parser.
    ///
    /// Defined on the non-generic `PercentEncoded` namespace, NOT nested in
    /// the generic `PercentEncoded.Parse<Input>`: a typed-throws error nested
    /// in a generic type carries that type parameter, tripping
    /// `FunctionSignatureOpts`' `!type.hasTypeParameter()` assertion on the
    /// typed-throws SIL argument under `-c release` (SILArgument.cpp:40).
    public enum Failure: Swift.Error, Sendable, Equatable {
        case expectedPercent
        case expectedHexDigit
    }

    /// Parses a percent-encoded triplet per RFC 3986 Section 2.1.
    ///
    /// `pct-encoded = "%" HEXDIG HEXDIG`
    ///
    /// Returns the decoded byte value (e.g., "%20" -> 0x20).
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
        // Expect '%'
        guard input.startIndex < input.endIndex, input[input.startIndex] == 0x25 else {
            throw .expectedPercent
        }
        input = input[input.index(after: input.startIndex)...]

        // First hex digit
        guard input.startIndex < input.endIndex else { throw .expectedHexDigit }
        guard let high = Self._hexValue(ASCII.Code(input[input.startIndex])) else { throw .expectedHexDigit }
        input = input[input.index(after: input.startIndex)...]

        // Second hex digit
        guard input.startIndex < input.endIndex else { throw .expectedHexDigit }
        guard let low = Self._hexValue(ASCII.Code(input[input.startIndex])) else { throw .expectedHexDigit }
        input = input[input.index(after: input.startIndex)...]

        return (high << 4) | low
    }

    @inlinable
    static func _hexValue(_ code: ASCII.Code) -> UInt8? {
        // Delegated to the L1 ASCII hex-digit table (single source of truth).
        // Byte-for-byte identical ranges: '0'–'9'→0–9, 'A'–'F'→10–15, 'a'–'f'→10–15.
        code.hexValue
    }
}

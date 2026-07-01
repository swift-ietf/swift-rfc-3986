//
//  RFC_3986.URI.Port.Parse.swift
//  swift-rfc-3986
//
//  URI port: *DIGIT → UInt16
//

public import Parser_Primitives
public import ASCII_Decimal_Parser_Primitives
import Byte_Primitives

extension RFC_3986.URI.Port {
    /// Parses a URI port number per RFC 3986 Section 3.2.3.
    ///
    /// `port = *DIGIT`
    ///
    /// Requires at least one digit. Returns the port as a UInt16.
    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == Byte {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Port {
    /// Failures from the byte-level port ``Parse`` parser, distinct from
    /// the validation ``Error``.
    ///
    /// Defined on the non-generic `Port` namespace, NOT nested in the
    /// generic `Port.Parse<Input>`: a typed-throws error nested in a generic
    /// type carries that type parameter, tripping `FunctionSignatureOpts`'
    /// `!type.hasTypeParameter()` assertion on the typed-throws SIL argument
    /// under `-c release` (SILArgument.cpp:40).
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
        // Delegate to the L1 ASCII decimal parser (single source of truth; it carries
        // the same checked overflow guard this site already used, via `T`-generic
        // `multipliedReportingOverflow`/`addingReportingOverflow`).
        do {
            return try ASCII.Decimal.Parser<Input, UInt16>().parse(&input)
        } catch {
            switch error {
            case .noDigits, .insufficientDigits, .invalidSign: throw .expectedDigit
            case .overflow: throw .overflow
            }
        }
    }
}

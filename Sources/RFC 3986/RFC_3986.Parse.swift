//
//  RFC_3986.Parse.swift
//  swift-rfc-3986
//
//  Namespace for URI parser combinators per RFC 3986 grammar.
//

import Parser_Primitives

extension RFC_3986 {
    public enum Parse {}
}

// MARK: - Character Classification Helpers

extension RFC_3986.Parse {
    /// unreserved = ALPHA / DIGIT / "-" / "." / "_" / "~"
    @inlinable
    public static func _isUnreserved(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x41...0x5A, 0x61...0x7A, 0x30...0x39: true
        case 0x2D, 0x2E, 0x5F, 0x7E: true
        default: false
        }
    }

    /// sub-delims = "!" / "$" / "&" / "'" / "(" / ")" / "*" / "+" / "," / ";" / "="
    @inlinable
    public static func _isSubDelim(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x21, 0x24, 0x26, 0x27, 0x28, 0x29: true
        case 0x2A, 0x2B, 0x2C, 0x3B, 0x3D: true
        default: false
        }
    }

    /// pchar = unreserved / pct-encoded / sub-delims / ":" / "@"
    @inlinable
    public static func _isPchar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte)
            || byte == 0x3A || byte == 0x40 || byte == 0x25
    }

    /// userinfo char = unreserved / pct-encoded / sub-delims / ":"
    @inlinable
    public static func _isUserinfoChar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte)
            || byte == 0x3A || byte == 0x25
    }

    /// reg-name char = unreserved / pct-encoded / sub-delims
    @inlinable
    public static func _isRegNameChar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte) || byte == 0x25
    }

    /// query/fragment char = pchar / "/" / "?"
    @inlinable
    public static func _isQueryOrFragmentChar(_ byte: UInt8) -> Bool {
        _isPchar(byte) || byte == 0x2F || byte == 0x3F
    }

    /// ALPHA per RFC 5234 Appendix B.1
    @inlinable
    public static func _isAlpha(_ byte: UInt8) -> Bool {
        (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A)
    }

    /// scheme trailing char = ALPHA / DIGIT / "+" / "-" / "."
    @inlinable
    public static func _isSchemeChar(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x41...0x5A, 0x61...0x7A, 0x30...0x39: true  // ALPHA / DIGIT
        case 0x2B, 0x2D, 0x2E: true  // "+" "-" "."
        default: false
        }
    }

    /// `scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." )` — the whole slice,
    /// not a prefix, must match (used to derive URI-reference validity from a
    /// full grammar match rather than a character blocklist).
    @inlinable
    public static func _isValidScheme<Bytes: Swift.Collection>(_ bytes: Bytes) -> Bool
    where Bytes.Element == UInt8 {
        guard let first = bytes.first, _isAlpha(first) else { return false }
        return bytes.dropFirst().allSatisfy(_isSchemeChar)
    }

    /// HEXDIG per RFC 5234 Appendix B.1
    @inlinable
    public static func _isHexDigit(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x30...0x39, 0x41...0x46, 0x61...0x66: true
        default: false
        }
    }

    /// Returns `true` if every byte in `bytes` either satisfies `isAllowed` or is
    /// part of a well-formed percent-encoded octet (`"%" HEXDIG HEXDIG`, RFC 3986
    /// Section 2.1).
    ///
    /// This is the shared grammar-conformance check used to derive URI-reference
    /// validity from the actual production character classes above (composing the
    /// `_is*Char` grammars already declared in this file) instead of an explicit
    /// forbidden-character blocklist: any byte outside both the allowed set and a
    /// correctly-formed `%HH` escape fails the match.
    @inlinable
    public static func _isGrammarValid<Bytes: Swift.Collection>(
        _ bytes: Bytes,
        allowedRawByte isAllowed: (UInt8) -> Bool
    ) -> Bool where Bytes.Element == UInt8 {
        var iterator = bytes.makeIterator()
        while let byte = iterator.next() {
            if byte == 0x25 {  // "%"
                guard let hi = iterator.next(), let lo = iterator.next(),
                    _isHexDigit(hi), _isHexDigit(lo)
                else { return false }
            } else if !isAllowed(byte) {
                return false
            }
        }
        return true
    }
}

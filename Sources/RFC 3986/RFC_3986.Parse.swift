import Parser_Primitives

extension RFC_3986 {
    public enum Parse {}
}

extension RFC_3986.Parse {

    @inlinable
    public static func _isUnreserved(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x41...0x5A, 0x61...0x7A, 0x30...0x39: true
        case 0x2D, 0x2E, 0x5F, 0x7E: true
        default: false
        }
    }

    @inlinable
    public static func _isSubDelim(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x21, 0x24, 0x26, 0x27, 0x28, 0x29: true
        case 0x2A, 0x2B, 0x2C, 0x3B, 0x3D: true
        default: false
        }
    }

    @inlinable
    public static func _isPchar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte)
            || byte == 0x3A || byte == 0x40 || byte == 0x25
    }

    @inlinable
    public static func _isUserinfoChar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte)
            || byte == 0x3A || byte == 0x25
    }

    @inlinable
    public static func _isRegNameChar(_ byte: UInt8) -> Bool {
        _isUnreserved(byte) || _isSubDelim(byte) || byte == 0x25
    }

    @inlinable
    public static func _isQueryOrFragmentChar(_ byte: UInt8) -> Bool {
        _isPchar(byte) || byte == 0x2F || byte == 0x3F
    }

    @inlinable
    public static func _isAlpha(_ byte: UInt8) -> Bool {
        (byte >= 0x41 && byte <= 0x5A) || (byte >= 0x61 && byte <= 0x7A)
    }

    @inlinable
    public static func _isSchemeChar(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x41...0x5A, 0x61...0x7A, 0x30...0x39: true
        case 0x2B, 0x2D, 0x2E: true
        default: false
        }
    }

    @inlinable
    public static func _isValidScheme<Bytes: Swift.Collection>(_ bytes: Bytes) -> Bool
    where Bytes.Element == UInt8 {
        guard let first = bytes.first, _isAlpha(first) else { return false }
        return bytes.dropFirst().allSatisfy(_isSchemeChar)
    }

    @inlinable
    public static func _isHexDigit(_ byte: UInt8) -> Bool {
        switch byte {
        case 0x30...0x39, 0x41...0x46, 0x61...0x66: true
        default: false
        }
    }

    @inlinable
    public static func _isGrammarValid<Bytes: Swift.Collection>(
        _ bytes: Bytes,
        allowedRawByte isAllowed: (UInt8) -> Bool
    ) -> Bool where Bytes.Element == UInt8 {
        var iterator = bytes.makeIterator()
        while let byte = iterator.next() {
            if byte == 0x25 {
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

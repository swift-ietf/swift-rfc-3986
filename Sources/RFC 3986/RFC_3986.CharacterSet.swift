public import ASCII_Primitives

extension RFC_3986 {

    public struct CharacterSet: Sendable, SetAlgebra {

        internal var characters: Set<Character>

        internal init(_ characters: Set<Character>) {
            self.characters = characters
        }

        public init() {
            self.characters = []
        }
    }
}

extension RFC_3986.CharacterSet {
    public func contains(_ member: Character) -> Bool {
        characters.contains(member)
    }

    public func union(_ other: Self) -> Self {
        Self(characters.union(other.characters))
    }

    public func intersection(_ other: Self) -> Self {
        Self(characters.intersection(other.characters))
    }

    public func symmetricDifference(_ other: Self) -> Self {
        Self(characters.symmetricDifference(other.characters))
    }

    @discardableResult
    public mutating func insert(
        _ newMember: Character
    ) -> (inserted: Bool, memberAfterInsert: Character) {
        characters.insert(newMember)
    }

    @discardableResult
    public mutating func remove(_ member: Character) -> Character? {
        characters.remove(member)
    }

    @discardableResult
    public mutating func update(with newMember: Character) -> Character? {
        characters.update(with: newMember)
    }

    public mutating func formUnion(_ other: Self) {
        characters.formUnion(other.characters)
    }

    public mutating func formIntersection(_ other: Self) {
        characters.formIntersection(other.characters)
    }

    public mutating func formSymmetricDifference(_ other: Self) {
        characters.formSymmetricDifference(other.characters)
    }
}

extension RFC_3986.CharacterSet {

    public static let unreserved: Self = .init(
        Set(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        )
    )

    public static let reserved: Self = .init(
        Set(
            ":/?#[]@!$&'()*+,;="
        )
    )

    public static let genDelims: Self = .init(
        Set(
            ":/?#[]@"
        )
    )

    public static let subDelims: Self = .init(
        Set(
            "!$&'()*+,;="
        )
    )

    public static let scheme: Self = .init(
        Set(
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+.-"
        )
    )

    public static let userinfo: Self = unreserved.union(subDelims).union(.init(Set([":"])))

    public static let host: Self = unreserved.union(subDelims)

    public static let pathSegment: Self = unreserved.union(subDelims).union(.init(Set([":", "@"])))

    public static let query: Self = pathSegment.union(.init(Set(["/", "?"])))

    public static let queryComponent: Self = query.subtracting(.init(Set(["&", "=", "#"])))

    public static let fragment: Self = query
}

extension RFC_3986 {

    public struct ByteSet: Sendable {

        @usableFromInline
        let low: UInt64

        @usableFromInline
        let high: UInt64

        @inlinable
        public init(low: UInt64, high: UInt64) {
            self.low = low
            self.high = high
        }

        @inlinable
        public init(ascii characters: String) {
            var lo: UInt64 = 0
            var hi: UInt64 = 0
            for byte in characters.utf8 where byte < 128 {
                if byte < 64 {
                    lo |= 1 << UInt64(byte)
                } else {
                    hi |= 1 << UInt64(byte - 64)
                }
            }
            self.low = lo
            self.high = hi
        }
    }
}

extension RFC_3986.ByteSet {

    @inlinable
    public func contains(_ byte: UInt8) -> Bool {
        guard byte < 128 else { return false }
        if byte < 64 {
            return (low & (1 << UInt64(byte))) != 0
        } else {
            return (high & (1 << UInt64(byte - 64))) != 0
        }
    }

    @inlinable
    public func union(_ other: RFC_3986.ByteSet) -> RFC_3986.ByteSet {
        RFC_3986.ByteSet(low: low | other.low, high: high | other.high)
    }

    @inlinable
    public func subtracting(_ other: RFC_3986.ByteSet) -> RFC_3986.ByteSet {
        RFC_3986.ByteSet(low: low & ~other.low, high: high & ~other.high)
    }
}

extension RFC_3986.ByteSet {

    public static let unreserved = RFC_3986.ByteSet(
        ascii: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
    )

    public static let reserved = RFC_3986.ByteSet(
        ascii: ":/?#[]@!$&'()*+,;="
    )

    public static let genDelims = RFC_3986.ByteSet(
        ascii: ":/?#[]@"
    )

    public static let subDelims = RFC_3986.ByteSet(
        ascii: "!$&'()*+,;="
    )

    public static let pathSegment = unreserved.union(subDelims).union(RFC_3986.ByteSet(ascii: ":@"))

    public static let query = pathSegment.union(RFC_3986.ByteSet(ascii: "/?"))
}

extension RFC_3986 {

    @inlinable
    public static func percentEncode<Bytes: Swift.Collection>(
        _ bytes: Bytes,
        allowing allowed: ByteSet = .unreserved
    ) -> [UInt8] where Bytes.Element == UInt8 {
        var result: [UInt8] = []
        result.reserveCapacity(bytes.count * 3)

        for byte in bytes {
            if allowed.contains(byte) {
                result.append(byte)
            } else {
                result.append(UInt8(ascii: "%"))
                result.append(hexDigit(byte >> 4))
                result.append(hexDigit(byte & 0x0F))
            }
        }
        return result
    }

    @inlinable
    public static func percentEncode<Bytes: Swift.Collection, Buffer: RangeReplaceableCollection>(
        _ bytes: Bytes,
        into buffer: inout Buffer,
        allowing allowed: ByteSet = .unreserved
    ) where Bytes.Element == UInt8, Buffer.Element == UInt8 {
        for byte in bytes {
            if allowed.contains(byte) {
                buffer.append(byte)
            } else {
                buffer.append(UInt8(ascii: "%"))
                buffer.append(hexDigit(byte >> 4))
                buffer.append(hexDigit(byte & 0x0F))
            }
        }
    }

    @inlinable
    public static func percentDecode<Bytes: Swift.Collection>(
        _ bytes: Bytes
    ) -> [UInt8] where Bytes.Element == UInt8 {
        var result: [UInt8] = []
        result.reserveCapacity(bytes.count)

        var iterator = bytes.makeIterator()
        while let byte = iterator.next() {
            if byte == UInt8(ascii: "%"),
                let hi = iterator.next(),
                let lo = iterator.next(),
                let hiVal = hexDigitValue(ASCII.Code(hi)),
                let loVal = hexDigitValue(ASCII.Code(lo))
            {
                result.append((hiVal << 4) | loVal)
            } else {
                result.append(byte)
            }
        }
        return result
    }

    @inlinable
    package static func hexDigit(_ nibble: UInt8) -> UInt8 {
        if nibble < 10 {
            return UInt8(ascii: "0") + nibble
        } else {
            return UInt8(ascii: "A") + nibble - 10
        }
    }

    @inlinable
    package static func hexDigitValue(_ code: ASCII.Code) -> UInt8? {

        code.hexValue
    }
}

extension RFC_3986 {

    public static func percentEncode(
        _ string: String,
        allowing allowedCharacters: RFC_3986.CharacterSet = .unreserved
    ) -> String {
        var result = ""
        let hexDigits = Array("0123456789ABCDEF")

        for character in string {
            if allowedCharacters.contains(character) {
                result.append(character)
            } else {

                for byte in String(character).utf8 {
                    result.append("%")
                    result.append(hexDigits[Int(byte >> 4)])
                    result.append(hexDigits[Int(byte & 0x0F)])
                }
            }
        }
        return result
    }

    public static func percentDecode(_ string: String) -> String {
        var bytes: [UInt8] = []
        var index = string.startIndex

        while index < string.endIndex {
            if string[index] == "%",
                let nextIndex = string.index(index, offsetBy: 1, limitedBy: string.endIndex),
                let thirdIndex = string.index(index, offsetBy: 3, limitedBy: string.endIndex)
            {
                let hexString = String(string[nextIndex..<thirdIndex])
                if let byte = UInt8(hexString, radix: 16) {
                    bytes.append(byte)
                    index = thirdIndex
                    continue
                }
            }

            for byte in String(string[index]).utf8 {
                bytes.append(byte)
            }
            index = string.index(after: index)
        }

        return String(decoding: bytes, as: UTF8.self)
    }

    public static func normalizePercentEncoding(_ string: String) -> String {
        var result = ""
        var index = string.startIndex

        while index < string.endIndex {
            if string[index] == "%",
                let nextIndex = string.index(index, offsetBy: 1, limitedBy: string.endIndex),
                let thirdIndex = string.index(index, offsetBy: 3, limitedBy: string.endIndex)
            {
                let hexString = String(string[nextIndex..<thirdIndex])

                let uppercasedHex = hexString.uppercased()

                if let byte = UInt8(uppercasedHex, radix: 16) {
                    let scalar = Unicode.Scalar(byte)
                    let character = Character(scalar)

                    if RFC_3986.CharacterSet.unreserved.contains(character) {
                        result.append(character)
                    } else {

                        result.append("%")
                        result.append(uppercasedHex)
                    }
                } else {

                    result.append(contentsOf: string[index..<thirdIndex])
                }

                index = thirdIndex
            } else {
                result.append(string[index])
                index = string.index(after: index)
            }
        }

        return result
    }
}

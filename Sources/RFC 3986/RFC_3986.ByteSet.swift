import ASCII

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

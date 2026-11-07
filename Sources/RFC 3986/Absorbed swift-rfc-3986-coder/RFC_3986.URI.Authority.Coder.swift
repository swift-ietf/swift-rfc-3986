#if Coder
    public import Byte
    public import Coder
    public import Cursor
    import Either
    import Parser
    import Serializer

    extension RFC_3986.URI.Authority {
        public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {
            public init() {}
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }

extension RFC_3986.URI.Authority.Coder {
        public typealias Failure = RFC_3986.URI.Authority.Error

        public typealias Output = RFC_3986.URI.Authority

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            var bytes: [Byte] = []
            while true {
                let saved = input.checkpoint
                guard let byte = input.next() else { break }
                if byte.bitPattern == 0x2F || byte.bitPattern == 0x3F || byte.bitPattern == 0x23 {
                    input.seek(to: saved)
                    break
                }
                bytes.append(byte)
            }
            return try Output(ascii: bytes)
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            RFC_3986.URI.Authority.serialize(output, into: &buffer)
        }
}
#endif

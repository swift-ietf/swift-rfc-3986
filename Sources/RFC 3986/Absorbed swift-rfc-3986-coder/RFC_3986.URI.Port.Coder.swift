#if Coder
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_3986.URI.Port {
        public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {
            public init() {}
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }
    }

    extension RFC_3986.URI.Port.Coder {
        public typealias Output = RFC_3986.URI.Port

        public typealias Failure = RFC_3986.URI.Port.Error

        public borrowing func parse(_ input: inout Input) throws(Failure) -> Output {
            let start = input.checkpoint
            let bytes = Scan.run(&input) { byte in (0x30...0x39).contains(byte) }
            do throws(Failure) {
                return try RFC_3986.URI.Port(ascii: bytes)
            } catch {
                input.seek(to: start)
                throw error
            }
        }

        public borrowing func serialize(_ output: Output, into buffer: inout Buffer) throws(Failure) {
            Scan.append(String(output.value), into: &buffer)
        }
    }
#endif

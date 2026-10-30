#if Coder
    import ASCII
    public import Byte
    public import Coder
    public import Cursor
    import Parser
    import Serializer

    extension RFC_3986 {

        public enum PercentEncoded {}
    }

    extension RFC_3986.PercentEncoded {

        public struct Coder<Input: Cursor.`Protocol`<Byte, Never>, Buffer: RangeReplaceableCollection<Byte>>: Coding {

            public typealias Output = Byte

            public typealias Failure = RFC_3986.PercentEncoded.Error

            public init() {}

            public borrowing func parse(_ input: inout Input) throws(Failure) -> Byte {
                let start = input.checkpoint

                guard let percent = input.next(), percent.bitPattern == 0x25 else {
                    input.seek(to: start)
                    throw .expectedPercent
                }
                guard let first = input.next(), let high = ASCII.Code(unchecked: first).hexValue else {
                    input.seek(to: start)
                    throw .expectedHexDigit
                }
                guard let second = input.next(), let low = ASCII.Code(unchecked: second).hexValue else {
                    input.seek(to: start)
                    throw .expectedHexDigit
                }
                return Byte(bitPattern: (high << 4) | low)
            }

            public borrowing func serialize(_ output: Byte, into buffer: inout Buffer) throws(Failure) {
                let digits: [UInt8] = Array("0123456789ABCDEF".utf8)
                buffer.append(Byte(bitPattern: 0x25))
                buffer.append(Byte(bitPattern: digits[Int(output.bitPattern >> 4)]))
                buffer.append(Byte(bitPattern: digits[Int(output.bitPattern & 0x0F)]))
            }
        }

        public static var coder: Coder<ArraySlice<Byte>, [Byte]> { .init() }

        public enum Error: Swift::Error, Equatable {
            case expectedPercent
            case expectedHexDigit
        }
    }
#endif

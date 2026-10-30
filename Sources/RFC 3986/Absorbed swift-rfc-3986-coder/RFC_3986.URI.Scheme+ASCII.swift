#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_3986.URI.Scheme: ASCII.Parseable {}

    extension RFC_3986.URI.Scheme: ASCII.Serializable, Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            for byte in value.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            for byte in value.rawValue.utf8 { buffer.append(Byte(bitPattern: byte)) }
        }
    }
#endif

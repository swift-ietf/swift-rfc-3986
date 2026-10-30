#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_3986.URI.Port: ASCII.Parseable {}

    extension RFC_3986.URI.Port: ASCII.Serializable, Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            for byte in String(value.value).utf8 { buffer.append(ASCII.Code(byte)) }
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            buffer.append(contentsOf: String(value.value).utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }
#endif

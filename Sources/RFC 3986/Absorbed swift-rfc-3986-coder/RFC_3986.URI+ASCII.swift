#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_3986.URI: ASCII.Parseable {}

    extension RFC_3986.URI: ASCII.Serializable, Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            for byte in value.description.utf8 { buffer.append(ASCII.Code(byte)) }
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            buffer.append(contentsOf: value.description.utf8.lazy.map(Byte.init(bitPattern:)))
        }
    }
#endif

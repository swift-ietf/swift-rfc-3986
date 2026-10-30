#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_3986.URI.Path: ASCII.Parseable {}

    extension RFC_3986.URI.Path: ASCII.Serializable, Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            if value.isAbsolute {
                buffer.append(ASCII.Code.solidus)
            }

            for (index, segment) in value.segments.enumerated() {
                if index > 0 {
                    buffer.append(ASCII.Code.solidus)
                }
                for byte in segment.utf8 { buffer.append(ASCII.Code(byte)) }
            }
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ value: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            if value.isAbsolute {
                buffer.append(ASCII.Code.solidus.byte)
            }

            for (index, segment) in value.segments.enumerated() {
                if index > 0 {
                    buffer.append(ASCII.Code.solidus.byte)
                }
                buffer.append(contentsOf: segment.utf8.lazy.map(Byte.init(bitPattern:)))
            }
        }
    }
#endif

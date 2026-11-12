#if Coder
    public import ASCII
    public import Binary
    public import Byte

    extension RFC_3986.URI.Authority: ASCII.Parseable {}

    extension RFC_3986.URI.Authority: ASCII.Serializable, Binary.Serializable {

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ authority: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == ASCII.Code {
            if let userinfo = authority.userinfo {
                RFC_3986.URI.Userinfo.serialize(userinfo, into: &buffer)
                buffer.append(ASCII.Code.atSign)
            }

            RFC_3986.URI.Host.serialize(authority.host, into: &buffer)

            if let port = authority.port {
                buffer.append(ASCII.Code.colon)
                for byte in String(port.value).utf8 { buffer.append(ASCII.Code(byte)) }
            }
        }

        public static func serialize<Buffer: RangeReplaceableCollection>(
            _ authority: Self,
            into buffer: inout Buffer
        ) where Buffer.Element == Byte {
            var codes: [ASCII.Code] = []
            Self.serialize(authority, into: &codes)
            buffer.append(contentsOf: codes.map({ $0.byte }))
        }
    }
#endif

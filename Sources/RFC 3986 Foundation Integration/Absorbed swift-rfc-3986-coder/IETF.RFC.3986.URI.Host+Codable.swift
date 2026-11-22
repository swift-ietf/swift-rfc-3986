#if Coder
    import ASCII
    public import RFC_3986

    extension IETF.RFC.`3986`.URI.Host: Encodable, Decodable {

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            do throws(IETF.RFC.`3986`.URI.Host.Error) {
                self = try IETF.RFC.`3986`.URI.Host(text)
            } catch {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "\(error)")
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var codes: [ASCII.Code] = []
            IETF.RFC.`3986`.URI.Host.serialize(self, into: &codes)

            var container = encoder.singleValueContainer()
            try container.encode(String(decoding: codes.map(\.underlying), as: UTF8.self))
        }
    }
#endif

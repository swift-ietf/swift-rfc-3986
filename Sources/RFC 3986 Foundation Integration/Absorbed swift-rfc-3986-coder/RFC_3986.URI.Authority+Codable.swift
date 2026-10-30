#if Coder
    import ASCII
    public import RFC_3986

    extension RFC_3986.URI.Authority: Encodable, Decodable {

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            do throws(RFC_3986.URI.Authority.Error) {
                self = try RFC_3986.URI.Authority(text)
            } catch {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "\(error)")
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var codes: [ASCII.Code] = []
            RFC_3986.URI.Authority.serialize(self, into: &codes)

            var container = encoder.singleValueContainer()
            try container.encode(String(decoding: codes.map(\.underlying), as: UTF8.self))
        }
    }
#endif

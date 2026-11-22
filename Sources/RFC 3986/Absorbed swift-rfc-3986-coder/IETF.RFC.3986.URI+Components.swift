#if Coder
    import Byte

    extension IETF.RFC.`3986`.URI {

        public init(
            scheme: IETF.RFC.`3986`.URI.Scheme,
            authority: IETF.RFC.`3986`.URI.Authority,
            path: IETF.RFC.`3986`.URI.Path,
            query: IETF.RFC.`3986`.URI.Query? = nil,
            fragment: IETF.RFC.`3986`.URI.Fragment? = nil
        ) {
            var bytes: [Byte] = []
            IETF.RFC.`3986`.URI.Authority.serialize(authority, into: &bytes)

            var text = "\(scheme.value)://"
            text += String(decoding: bytes, as: UTF8.self)
            text += path.description

            if let query {
                text += "?\(query.description)"
            }

            if let fragment {
                text += "#\(fragment.value)"
            }

            self.init(unchecked: text)
        }
    }
#endif

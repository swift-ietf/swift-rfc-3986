#if Coder
    import Byte

    extension RFC_3986.URI {

        public init(
            scheme: RFC_3986.URI.Scheme,
            authority: RFC_3986.URI.Authority,
            path: RFC_3986.URI.Path,
            query: RFC_3986.URI.Query? = nil,
            fragment: RFC_3986.URI.Fragment? = nil
        ) {
            var bytes: [Byte] = []
            RFC_3986.URI.Authority.serialize(authority, into: &bytes)

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

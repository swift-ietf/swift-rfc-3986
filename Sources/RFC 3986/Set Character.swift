extension Set<Character> {

    public enum URI {}
}

extension Set<Character>.URI {

    public static var unreserved: Set<Character> {
        RFC_3986.CharacterSet.unreserved.characters
    }

    public static var reserved: Set<Character> {
        RFC_3986.CharacterSet.reserved.characters
    }

    public static var genDelims: Set<Character> {
        RFC_3986.CharacterSet.genDelims.characters
    }

    public static var subDelims: Set<Character> {
        RFC_3986.CharacterSet.subDelims.characters
    }

    public static var scheme: Set<Character> {
        RFC_3986.CharacterSet.scheme.characters
    }

    public static var userinfo: Set<Character> {
        RFC_3986.CharacterSet.userinfo.characters
    }

    public static var host: Set<Character> {
        RFC_3986.CharacterSet.host.characters
    }

    public static var pathSegment: Set<Character> {
        RFC_3986.CharacterSet.pathSegment.characters
    }

    public static var query: Set<Character> {
        RFC_3986.CharacterSet.query.characters
    }

    public static var fragment: Set<Character> {
        RFC_3986.CharacterSet.fragment.characters
    }
}

extension Set<Character> {

    public static var uri: URI.Type {
        URI.self
    }
}

extension Set<Character> {

    public init(_ characterSet: RFC_3986.CharacterSet) {
        self = characterSet.characters
    }
}

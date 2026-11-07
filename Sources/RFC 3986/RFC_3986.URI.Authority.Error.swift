public import Byte


extension RFC_3986.URI.Authority {
    public enum Error: Swift::Error, Sendable, Equatable, CustomStringConvertible {

        case invalidUserinfo(String, underlying: any Swift::Error)

        case invalidHost(String, underlying: any Swift::Error)

        case invalidPort(String)

        case unterminatedIPv6(String)

        case invalidCharactersAfterIPv6(String)
    }
}

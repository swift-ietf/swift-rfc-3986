#if Coder
public import ASCII
internal import RFC_4007
public import RFC_4291
internal import RFC_791
public import RFC_5952_Coder
public import Serializer

extension RFC_3986.URI.Host {

    public struct Text: Serializer::Serializing {
        public init() {}
    }
}

extension RFC_3986.URI.Host.Text {
    public typealias Output = RFC_3986.URI.Host
    public typealias Buffer = [ASCII.Code]
    public typealias Failure = Never

    public borrowing func serialize(
        _ host: RFC_3986.URI.Host,
        into buffer: inout [ASCII.Code]
    ) {
        switch host {
        case .ipv4(let address):
            for byte in address.description.utf8 { buffer.append(ASCII.Code(byte)) }

        case .ipv6(let scopedAddress):
            buffer.append(.leftBracket)
            RFC_4291.IPv6.Address.Text.Canonical().serialize(scopedAddress.address, into: &buffer)
            if let zone = scopedAddress.zone {
                buffer.append(.percentSign)
                buffer.append(.`2`)
                buffer.append(.`5`)
                for byte in zone.utf8 { buffer.append(ASCII.Code(byte)) }
            }
            buffer.append(.rightBracket)

        case .registeredName(let name):
            for byte in name.utf8 { buffer.append(ASCII.Code(byte)) }
        }
    }
}
#endif

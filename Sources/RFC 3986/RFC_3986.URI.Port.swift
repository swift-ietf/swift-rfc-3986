public import ASCII_Serializer
public import Binary_Serializable
public import Parseable_ASCII
import Byte
import Byte_Standard_Library_Integration

extension RFC_3986.URI {

    public struct Port: Sendable, Equatable, Hashable {

        public let value: UInt16

        init(
            __unchecked _: Void,
            value: UInt16
        ) {
            self.value = value
        }
    }
}

extension RFC_3986.URI.Port: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in String(value.value).utf8 { buffer.append(ASCII.Code(byte)) }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ port: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: String(port.value).utf8.lazy.map(Byte.init(bitPattern:)))
    }
}

extension RFC_3986.URI.Port: ASCII.Parseable {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        var result: UInt32 = 0

        for byte in bytes {

            let code: ASCII.Code
            do throws(ASCII.Code.Error) {
                code = try ASCII.Code(byte)
            } catch {
                switch error {
                case .notASCII(let badByte):
                    throw Error.invalidCharacter(
                        String(decoding: bytes, as: UTF8.self),
                        byte: badByte
                    )
                }
            }
            guard code.isDigit else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte
                )
            }

            let digit = UInt32(code.digitValue!)
            result = result * 10 + digit

            guard result <= UInt32(UInt16.max) else {
                throw Error.overflow(String(decoding: bytes, as: UTF8.self))
            }
        }

        self.init(__unchecked: (), value: UInt16(result))
    }
}

extension RFC_3986.URI.Port: Swift.RawRepresentable {

    public typealias RawValue = UInt16

    public var rawValue: UInt16 {
        value
    }

    public init?(rawValue: UInt16) {
        self.init(__unchecked: (), value: rawValue)
    }
}
extension RFC_3986.URI.Port: CustomStringConvertible {
    public var description: String {
        String(value)
    }
}

extension RFC_3986.URI.Port {

    public init(_ value: UInt16) {
        self.init(__unchecked: (), value: value)
    }

    public init?(_ string: String) {
        guard let port = UInt16(string) else { return nil }
        self.init(port)
    }
}

extension RFC_3986.URI.Port {

    public static let http = Self(80)

    public static let https = Self(443)

    public static let ftp = Self(21)

    public static let ftps = Self(990)

    public static let ssh = Self(22)

    public static let telnet = Self(23)

    public static let smtp = Self(25)

    public static let dns = Self(53)

    public static let dhcpServer = Self(67)

    public static let dhcpClient = Self(68)

    public static let pop3 = Self(110)

    public static let imap = Self(143)

    public static let snmp = Self(161)

    public static let ldap = Self(389)

    public static let ldaps = Self(636)

    public static let mysql = Self(3306)

    public static let postgresql = Self(5432)

    public static let redis = Self(6379)

    public static let mongodb = Self(27017)
}

extension RFC_3986.URI.Port {

    public var isWellKnown: Bool {
        value < 1024
    }

    public var isRegistered: Bool {
        value >= 1024 && value < 49152
    }

    public var isDynamic: Bool {
        value >= 49152
    }
}

extension RFC_3986.URI.Port: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt16) {
        self.init(value)
    }
}

extension RFC_3986.URI.Port: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(UInt16.self)
        self.init(value)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension RFC_3986.URI.Port: Comparable {
    public static func < (lhs: RFC_3986.URI.Port, rhs: RFC_3986.URI.Port) -> Bool {
        lhs.value < rhs.value
    }
}

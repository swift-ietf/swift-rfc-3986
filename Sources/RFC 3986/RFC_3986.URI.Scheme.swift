public import ASCII_Serializer
public import Binary_Serializable
public import Parseable_ASCII

extension RFC_3986.URI {

    public struct Scheme: Sendable, Equatable, Hashable, Codable {

        public let rawValue: String

        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue.lowercased()
        }
    }
}

extension RFC_3986.URI.Scheme {

    public typealias RawValue = String
}

extension RFC_3986.URI.Scheme: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in value.rawValue.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        for byte in value.rawValue.utf8 { buffer.append(Byte(byte)) }
    }
}

extension RFC_3986.URI.Scheme: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

extension RFC_3986.URI.Scheme: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard let firstByte = bytes.first else {
            throw Error.empty
        }

        let firstCode: ASCII.Code
        do throws(ASCII.Code.Error) {
            firstCode = try ASCII.Code(firstByte)
        } catch {
            switch error {
            case .notASCII(let badByte):
                throw Error.invalidStart(String(decoding: bytes, as: UTF8.self), byte: badByte)
            }
        }
        guard firstCode.isLetter else {
            throw Error.invalidStart(String(decoding: bytes, as: UTF8.self), byte: firstCode.byte)
        }

        for byte in bytes.dropFirst() {
            let code: ASCII.Code
            do throws(ASCII.Code.Error) {
                code = try ASCII.Code(byte)
            } catch {
                switch error {
                case .notASCII(let badByte):
                    throw Error.invalidCharacter(
                        String(decoding: bytes, as: UTF8.self),
                        byte: badByte,
                        reason: "Only letters, digits, +, -, . allowed"
                    )
                }
            }
            let valid =
                code.isLetter
                || code.isDigit
                || code == ASCII.Code.plusSign
                || code == ASCII.Code.hyphen
                || code == ASCII.Code.period
            guard valid else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte,
                    reason: "Only letters, digits, +, -, . allowed"
                )
            }
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

extension RFC_3986.URI.Scheme {

    public static let http = Self(__unchecked: (), rawValue: "http")

    public static let https = Self(__unchecked: (), rawValue: "https")

    public static let ftp = Self(__unchecked: (), rawValue: "ftp")

    public static let ftps = Self(__unchecked: (), rawValue: "ftps")

    public static let file = Self(__unchecked: (), rawValue: "file")

    public static let ws = Self(__unchecked: (), rawValue: "ws")

    public static let wss = Self(__unchecked: (), rawValue: "wss")

    public static let mailto = Self(__unchecked: (), rawValue: "mailto")

    public static let data = Self(__unchecked: (), rawValue: "data")
}

extension RFC_3986.URI.Scheme {

    public var value: String { rawValue }

    public var isSecure: Bool {
        switch rawValue {
        case "https", "wss", "ftps":
            return true

        default:
            return false
        }
    }

    public var isHTTP: Bool {
        rawValue == "http" || rawValue == "https"
    }

    public var defaultPort: UInt16? {
        switch rawValue {
        case "http": return 80
        case "https": return 443
        case "ftp": return 21
        case "ftps": return 990
        case "ws": return 80
        case "wss": return 443
        default: return nil
        }
    }
}

extension RFC_3986.URI.Scheme {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension RFC_3986.URI.Scheme: Comparable {
    public static func < (lhs: RFC_3986.URI.Scheme, rhs: RFC_3986.URI.Scheme) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

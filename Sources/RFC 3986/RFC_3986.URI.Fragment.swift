public import ASCII_Serializer
public import Binary_Serializable
public import Parseable_ASCII
import Byte
import Byte_Standard_Library_Integration

extension RFC_3986.URI {

    public struct Fragment: Sendable, Equatable, Hashable, Codable {

        public let rawValue: String

        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

extension RFC_3986.URI.Fragment {

    public typealias RawValue = String
}

extension RFC_3986.URI.Fragment: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {

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
        for byte in value.rawValue.utf8 { buffer.append(Byte(bitPattern: byte)) }
    }
}

extension RFC_3986.URI.Fragment: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        for byte in bytes {
            let code: ASCII.Code
            do throws(ASCII.Code.Error) {
                code = try ASCII.Code(byte)
            } catch {
                switch error {
                case .notASCII(let badByte):
                    throw Error.invalidCharacter(
                        String(decoding: bytes, as: UTF8.self),
                        byte: badByte,
                        reason: "non-ASCII byte in fragment"
                    )
                }
            }

            if code == ASCII.Code.numberSign {
                throw Error.containsHash(String(decoding: bytes, as: UTF8.self))
            }

            if code == ASCII.Code.lf || code == ASCII.Code.cr {
                throw Error.containsNewline(String(decoding: bytes, as: UTF8.self))
            }
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

extension RFC_3986.URI.Fragment: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

extension RFC_3986.URI.Fragment {

    public var value: String { rawValue }

    public var string: String {
        rawValue
    }

    public var isEmpty: Bool {
        rawValue.isEmpty
    }
}

extension RFC_3986.URI.Fragment {

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

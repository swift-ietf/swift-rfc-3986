public import Byte
import ASCII
import Byte_Standard_Library_Integration

extension RFC_3986.URI {

    public struct Fragment: Sendable, Equatable, Hashable {

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

extension RFC_3986.URI.Fragment: Swift.RawRepresentable {

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_3986.URI.Fragment {

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
        rawValue
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


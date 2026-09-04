public import Byte
import ASCII
import Byte_Standard_Library_Integration

extension RFC_3986.URI {

    public struct Userinfo: Sendable, Equatable, Hashable {

        public let rawValue: String

        init(
            __unchecked _: Void,
            rawValue: String
        ) {
            self.rawValue = rawValue
        }
    }
}

extension RFC_3986.URI.Userinfo {

    public typealias RawValue = String
}

extension RFC_3986.URI.Userinfo: Swift.RawRepresentable {

    public init?(rawValue: String) {
        do throws(Error) {
            try self.init(rawValue)
        } catch {
            return nil
        }
    }
}

extension RFC_3986.URI.Userinfo {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        let arr: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            var codes: [ASCII.Code] = []
            codes.reserveCapacity(bytes.count)
            for byte in bytes {
                codes.append(try ASCII.Code(byte))
            }
            arr = codes
        } catch {
            switch error {
            case .notASCII(let byte):
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "non-ASCII byte in userinfo"
                )
            }
        }

        var i = 0
        while i < arr.count {
            let code = arr[i]

            if code == ASCII.Code.percentSign {

                let next1 = i + 1
                guard next1 < arr.count else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "'%' must be followed by 2 hex digits"
                    )
                }
                let next2 = next1 + 1
                guard next2 < arr.count else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "'%' must be followed by 2 hex digits"
                    )
                }

                guard arr[next1].isHexDigit && arr[next2].isHexDigit else {
                    throw Error.invalidPercentEncoding(
                        String(decoding: bytes, as: UTF8.self),
                        reason: "Invalid hex digits after '%'"
                    )
                }

                i = next2 + 1
                continue
            }

            let isUnreserved =
                code.isLetter || code.isDigit
                || code == ASCII.Code.hyphen || code == ASCII.Code.period
                || code == ASCII.Code.underline || code == ASCII.Code.tilde
            let isSubDelim =
                code == ASCII.Code.exclamationPoint || code == ASCII.Code.dollarSign
                || code == ASCII.Code.ampersand || code == ASCII.Code.apostrophe
                || code == ASCII.Code.leftParenthesis || code == ASCII.Code.rightParenthesis
                || code == ASCII.Code.asterisk || code == ASCII.Code.plusSign
                || code == ASCII.Code.comma || code == ASCII.Code.semicolon
                || code == ASCII.Code.equalsSign
            let isColon = code == ASCII.Code.colon

            guard isUnreserved || isSubDelim || isColon else {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte,
                    reason: "Only unreserved, sub-delims, ':', and percent-encoded allowed"
                )
            }

            i += 1
        }

        self.init(__unchecked: (), rawValue: String(decoding: bytes, as: UTF8.self))
    }
}

extension RFC_3986.URI.Userinfo: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

extension RFC_3986.URI.Userinfo {

    public var user: String {
        if let colonIndex = rawValue.firstIndex(of: ":") {
            return String(rawValue[..<colonIndex])
        }
        return rawValue
    }

    public var password: String? {
        guard let colonIndex = rawValue.firstIndex(of: ":") else {
            return nil
        }
        let afterColon = rawValue.index(after: colonIndex)
        return afterColon < rawValue.endIndex ? String(rawValue[afterColon...]) : nil
    }
}


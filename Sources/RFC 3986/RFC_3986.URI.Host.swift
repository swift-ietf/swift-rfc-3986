public import Byte
public import IPv4_Standard
public import IPv6_Standard
import ASCII
import Byte_Standard_Library_Integration

extension RFC_3986.URI {

    public enum Host: Sendable, Equatable, Hashable {

        case ipv4(RFC_791.IPv4.Address)

        case ipv6(RFC_4007.IPv6.ScopedAddress)

        case registeredName(String)
    }
}

extension RFC_3986.URI.Host {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        guard !bytes.isEmpty else {
            throw Error.empty
        }

        let string = String(decoding: bytes, as: UTF8.self)

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
                throw Error.invalidCharacter(string, byte: byte, reason: "non-ASCII byte in host")
            }
        }

        if arr.first == ASCII.Code.leftBracket {

            guard arr.last == ASCII.Code.rightBracket else {
                throw Error.invalidIPv6(string, reason: "Missing closing bracket")
            }

            let innerCodes = arr.dropFirst().dropLast()

            let innerArray = Array(innerCodes)
            var decodedBytes: [Byte] = []
            decodedBytes.reserveCapacity(innerArray.count)

            var i = 0
            while i < innerArray.count {
                if innerArray[i] == ASCII.Code.percentSign {

                    if i + 2 < innerArray.count
                        && innerArray[i + 1] == ASCII.Code.`2`
                        && innerArray[i + 2] == ASCII.Code.`5`
                    {

                        decodedBytes.append(ASCII.Code.percentSign.byte)
                        i += 3
                        continue
                    }
                }
                decodedBytes.append(innerArray[i].byte)
                i += 1
            }

            do throws(RFC_4007.IPv6.ScopedAddress.Error) {
                let scopedAddress = try RFC_4007.IPv6.ScopedAddress(ascii: decodedBytes)
                self = .ipv6(scopedAddress)
                return
            } catch {
                let innerString = String(decoding: innerCodes.lazy.map(\.underlying), as: UTF8.self)
                throw Error.invalidIPv6(innerString, reason: "Invalid IPv6 address")
            }
        }

        do throws(RFC_791.IPv4.Address.Error) {
            let ipv4Address = try RFC_791.IPv4.Address(ascii: bytes)
            self = .ipv4(ipv4Address)
            return
        } catch {

        }

        for code in arr {

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
            let isPercent = code == ASCII.Code.percentSign

            guard isUnreserved || isSubDelim || isPercent else {
                throw Error.invalidCharacter(
                    string,
                    byte: code.byte,
                    reason:
                        "Only unreserved, sub-delims, and percent-encoded allowed in registered name"
                )
            }
        }

        self = .registeredName(string.lowercased())
    }
}

extension RFC_3986.URI.Host: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}

extension RFC_3986.URI.Host {

    public var rawValue: String {
        switch self {
        case .ipv4(let address):
            return address.description

        case .ipv6(let scopedAddress):
            var codes: [ASCII.Code] = []
            RFC_4291.IPv6.Address.serialize(scopedAddress.address, into: &codes)
            let address = String(decoding: codes.map(\.byte), as: UTF8.self)
            guard let zone = scopedAddress.zone else {
                return "[\(address)]"
            }
            return "[\(address)%25\(zone)]"

        case .registeredName(let name):
            return name
        }
    }

    public var isLoopback: Bool {
        switch self {
        case .ipv4(let address):

            return address.octets.0.bitPattern == 127

        case .ipv6(let scopedAddress):
            return scopedAddress.address.is.loopback

        case .registeredName(let name):
            return name == "localhost"
        }
    }

    public var ipv4Address: RFC_791.IPv4.Address? {
        if case .ipv4(let address) = self {
            return address
        }
        return nil
    }

    public var ipv6ScopedAddress: RFC_4007.IPv6.ScopedAddress? {
        if case .ipv6(let scopedAddress) = self {
            return scopedAddress
        }
        return nil
    }

    public var ipv6Address: RFC_4291.IPv6.Address? {
        if case .ipv6(let scopedAddress) = self {
            return scopedAddress.address
        }
        return nil
    }

    public var registeredNameValue: String? {
        if case .registeredName(let name) = self {
            return name
        }
        return nil
    }
}


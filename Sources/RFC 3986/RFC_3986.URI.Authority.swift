public import Byte
import ASCII
import Byte_Standard_Library_Integration

extension RFC_3986.URI {

    public struct Authority: Sendable, Equatable, Hashable {

        @available(*, deprecated, message: "deprecated for security reasons")
        public let userinfo: RFC_3986.URI.Userinfo?

        public let host: RFC_3986.URI.Host

        public let port: RFC_3986.URI.Port?

        init(
            __unchecked _: Void,
            userinfo: RFC_3986.URI.Userinfo?,
            host: RFC_3986.URI.Host,
            port: RFC_3986.URI.Port?
        ) {
            self.userinfo = userinfo
            self.host = host
            self.port = port
        }

        public init(
            userinfo: RFC_3986.URI.Userinfo? = nil,
            host: RFC_3986.URI.Host,
            port: RFC_3986.URI.Port? = nil
        ) {
            self.init(__unchecked: (), userinfo: userinfo, host: host, port: port)
        }
    }
}

extension RFC_3986.URI.Authority {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {
        let string = String(decoding: bytes, as: UTF8.self)
        var remaining = string

        let userinfo: RFC_3986.URI.Userinfo?
        if let atIndex = remaining.firstIndex(of: "@") {
            let userinfoString = String(remaining[..<atIndex])
            do throws(RFC_3986.URI.Userinfo.Error) {
                userinfo = try RFC_3986.URI.Userinfo(userinfoString)
            } catch {
                throw Error.invalidUserinfo(userinfoString, underlying: error)
            }
            remaining = String(remaining[remaining.index(after: atIndex)...])
        } else {
            userinfo = nil
        }

        let port: RFC_3986.URI.Port?
        let host: RFC_3986.URI.Host

        if remaining.hasPrefix("[") {

            guard let closeBracket = remaining.firstIndex(of: "]") else {
                throw Error.unterminatedIPv6(string)
            }

            let hostString = String(remaining[...closeBracket])
            remaining = String(remaining[remaining.index(after: closeBracket)...])

            if remaining.hasPrefix(":") {
                let portString = String(remaining.dropFirst())
                guard let portNumber = UInt16(portString) else {
                    throw Error.invalidPort(portString)
                }
                let portValue = RFC_3986.URI.Port(portNumber)
                port = portValue
            } else if !remaining.isEmpty {
                throw Error.invalidCharactersAfterIPv6(remaining)
            } else {
                port = nil
            }

            do throws(RFC_3986.URI.Host.Error) {
                host = try RFC_3986.URI.Host(hostString)
            } catch {
                throw Error.invalidHost(hostString, underlying: error)
            }
        } else {

            if let colonIndex = remaining.lastIndex(of: ":") {
                let hostString = String(remaining[..<colonIndex])
                let portString = String(remaining[remaining.index(after: colonIndex)...])

                guard let portNumber = UInt16(portString) else {
                    throw Error.invalidPort(portString)
                }
                let portValue = RFC_3986.URI.Port(portNumber)

                do throws(RFC_3986.URI.Host.Error) {
                    host = try RFC_3986.URI.Host(hostString)
                } catch {
                    throw Error.invalidHost(hostString, underlying: error)
                }
                port = portValue
            } else {
                do throws(RFC_3986.URI.Host.Error) {
                    host = try RFC_3986.URI.Host(remaining)
                } catch {
                    throw Error.invalidHost(remaining, underlying: error)
                }
                port = nil
            }
        }

        self.init(__unchecked: (), userinfo: userinfo, host: host, port: port)
    }
}

extension RFC_3986.URI.Authority {

    public init(_ string: some StringProtocol) throws(Error) {
        var remaining = String(string)

        let userinfo: RFC_3986.URI.Userinfo?
        if let atIndex = remaining.firstIndex(of: "@") {
            let userinfoString = String(remaining[..<atIndex])
            do throws(RFC_3986.URI.Userinfo.Error) {
                userinfo = try RFC_3986.URI.Userinfo(userinfoString)
            } catch {
                throw Error.invalidUserinfo(userinfoString, underlying: error)
            }
            remaining = String(remaining[remaining.index(after: atIndex)...])
        } else {
            userinfo = nil
        }

        let port: RFC_3986.URI.Port?
        let host: RFC_3986.URI.Host

        if remaining.hasPrefix("[") {

            guard let closeBracket = remaining.firstIndex(of: "]") else {
                throw Error.unterminatedIPv6(String(string))
            }

            let hostString = String(remaining[...closeBracket])
            remaining = String(remaining[remaining.index(after: closeBracket)...])

            if remaining.hasPrefix(":") {
                let portString = String(remaining.dropFirst())
                guard let portNumber = UInt16(portString) else {
                    throw Error.invalidPort(portString)
                }
                let portValue = RFC_3986.URI.Port(portNumber)
                port = portValue
            } else if !remaining.isEmpty {
                throw Error.invalidCharactersAfterIPv6(remaining)
            } else {
                port = nil
            }

            do throws(RFC_3986.URI.Host.Error) {
                host = try RFC_3986.URI.Host(hostString)
            } catch {
                throw Error.invalidHost(hostString, underlying: error)
            }
        } else {

            if let colonIndex = remaining.lastIndex(of: ":") {
                let hostString = String(remaining[..<colonIndex])
                let portString = String(remaining[remaining.index(after: colonIndex)...])

                guard let portNumber = UInt16(portString) else {
                    throw Error.invalidPort(portString)
                }
                let portValue = RFC_3986.URI.Port(portNumber)

                do throws(RFC_3986.URI.Host.Error) {
                    host = try RFC_3986.URI.Host(hostString)
                } catch {
                    throw Error.invalidHost(hostString, underlying: error)
                }
                port = portValue
            } else {
                do throws(RFC_3986.URI.Host.Error) {
                    host = try RFC_3986.URI.Host(remaining)
                } catch {
                    throw Error.invalidHost(remaining, underlying: error)
                }
                port = nil
            }
        }

        self.init(userinfo: userinfo, host: host, port: port)
    }
}

extension RFC_3986.URI.Authority {

    public var rawValue: String {
        var result = ""

        if let userinfo {
            result += "\(userinfo.rawValue)@"
        }

        result += host.rawValue

        if let port {
            result += ":\(port.value)"
        }

        return result
    }
}

extension RFC_3986.URI.Authority: CustomStringConvertible {
    public var description: String {
        rawValue
    }
}


extension RFC_3986.URI.Authority {

    public enum Error: Swift.Error, Sendable, Equatable, CustomStringConvertible {

        case invalidUserinfo(String, underlying: any Swift.Error)

        case invalidHost(String, underlying: any Swift.Error)

        case invalidPort(String)

        case unterminatedIPv6(String)

        case invalidCharactersAfterIPv6(String)
    }
}

extension RFC_3986.URI.Authority.Error {
    public var description: String {
        switch self {
        case .invalidUserinfo(let value, _):
            return "Invalid userinfo: '\(value)'"

        case .invalidHost(let value, _):
            return "Invalid host: '\(value)'"

        case .invalidPort(let value):
            return "Invalid port: '\(value)'"

        case .unterminatedIPv6(let value):
            return "Unterminated IPv6 address in: '\(value)'"

        case .invalidCharactersAfterIPv6(let value):
            return "Invalid characters after IPv6 address: '\(value)'"
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.invalidUserinfo(let l, _), .invalidUserinfo(let r, _)): l == r
        case (.invalidHost(let l, _), .invalidHost(let r, _)): l == r
        case (.invalidPort(let l), .invalidPort(let r)): l == r
        case (.unterminatedIPv6(let l), .unterminatedIPv6(let r)): l == r
        case (.invalidCharactersAfterIPv6(let l), .invalidCharactersAfterIPv6(let r)): l == r
        default: false
        }
    }
}

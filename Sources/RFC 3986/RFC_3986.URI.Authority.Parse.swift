public import Byte
public import Cursor
public import Parser
import Checkpoint
import Iterator_Protocol

extension RFC_3986.URI.Authority {

    public struct Parse<Input: Cursor.`Protocol`>: Sendable
    where Input.Element == Byte, Input.Failure == Never {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Authority.Parse {
    public struct Output: Sendable {
        public let userinfo: [Byte]?
        public let host: [Byte]
        public let port: UInt16?

        @inlinable
        public init(userinfo: [Byte]?, host: [Byte], port: UInt16?) {
            self.userinfo = userinfo
            self.host = host
            self.port = port
        }
    }

}

extension RFC_3986.URI.Authority {

    public enum ParseFailure: Swift.Error, Sendable, Equatable {
        case unterminatedIPLiteral
        case portOverflow
    }
}

extension RFC_3986.URI.Authority.Parse: Parser.`Protocol` {
    public typealias Failure = RFC_3986.URI.Authority.ParseFailure
    public typealias Body = Never

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {
        let start = input.checkpoint

        var scanned: [Byte] = []
        var userinfo: [Byte]? = nil

        while let byte = input.next() {
            let raw = byte.bitPattern
            if raw == 0x40 {
                userinfo = scanned
                break
            }
            if raw == 0x2F || raw == 0x3F || raw == 0x23 { break }
            scanned.append(byte)
        }

        if userinfo == nil { input.seek(to: start) }

        let host: [Byte]
        let hostStart = input.checkpoint

        if let first = input.next() {
            if first.bitPattern == 0x5B {
                var literal: [Byte] = [first]
                var terminated = false
                while let byte = input.next() {
                    literal.append(byte)
                    if byte.bitPattern == 0x5D {
                        terminated = true
                        break
                    }
                }
                guard terminated else {
                    input.seek(to: start)
                    throw .unterminatedIPLiteral
                }
                host = literal
            } else if RFC_3986.Parse._isRegNameChar(first.bitPattern) {
                var name: [Byte] = [first]
                var checkpoint = input.checkpoint
                while let byte = input.next() {
                    guard RFC_3986.Parse._isRegNameChar(byte.bitPattern) else {
                        input.seek(to: checkpoint)
                        break
                    }
                    name.append(byte)
                    checkpoint = input.checkpoint
                }
                host = name
            } else {
                input.seek(to: hostStart)
                host = []
            }
        } else {
            host = []
        }

        return try _parsePort(&input, userinfo: userinfo, host: host)
    }

    @inlinable
    package func _parsePort(
        _ input: inout Input,
        userinfo: [Byte]?,
        host: [Byte]
    ) throws(Failure) -> Output {
        var port: UInt16? = nil
        let colonStart = input.checkpoint

        guard let colon = input.next(), colon.bitPattern == 0x3A else {
            input.seek(to: colonStart)
            return Output(userinfo: userinfo, host: host, port: port)
        }

        var hasDigits = false
        var portValue: UInt16 = 0
        var checkpoint = input.checkpoint

        while let byte = input.next() {
            let raw = byte.bitPattern
            guard raw >= 0x30, raw <= 0x39 else {
                input.seek(to: checkpoint)
                break
            }
            hasDigits = true
            let digit = UInt16(raw &- 0x30)
            let (v1, o1) = portValue.multipliedReportingOverflow(by: 10)
            let (v2, o2) = v1.addingReportingOverflow(digit)
            guard !o1 && !o2 else { throw .portOverflow }
            portValue = v2
            checkpoint = input.checkpoint
        }

        if hasDigits {
            port = portValue
        }

        return Output(userinfo: userinfo, host: host, port: port)
    }
}

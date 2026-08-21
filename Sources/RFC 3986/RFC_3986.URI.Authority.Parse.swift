public import Parser_Primitives

extension RFC_3986.URI.Authority {

    public struct Parse<Input: Collection.Slice.`Protocol`>: Sendable
    where Input: Sendable, Input.Element == UInt8 {
        @inlinable
        public init() {}
    }
}

extension RFC_3986.URI.Authority.Parse {
    public struct Output: Sendable {
        public let userinfo: Input?
        public let host: Input
        public let port: UInt16?

        @inlinable
        public init(userinfo: Input?, host: Input, port: UInt16?) {
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

    @inlinable
    public func parse(_ input: inout Input) throws(Failure) -> Output {

        var userinfo: Input? = nil
        let saved = input
        var scanIndex = input.startIndex
        var foundAt = false
        while scanIndex < input.endIndex {
            let byte = input[scanIndex]
            if byte == 0x40 {
                foundAt = true
                break
            }

            if byte == 0x2F || byte == 0x3F || byte == 0x23 { break }
            input.formIndex(after: &scanIndex)
        }

        if foundAt {
            userinfo = input[input.startIndex..<scanIndex]
            input = input[input.index(after: scanIndex)...]
        } else {
            input = saved
        }

        let host: Input
        if input.startIndex < input.endIndex && input[input.startIndex] == 0x5B {

            var index = input.startIndex
            input.formIndex(after: &index)
            while index < input.endIndex {
                if input[index] == 0x5D {
                    input.formIndex(after: &index)
                    host = input[input.startIndex..<index]
                    input = input[index...]
                    return try _parsePort(&input, userinfo: userinfo, host: host)
                }
                input.formIndex(after: &index)
            }
            throw .unterminatedIPLiteral
        } else {

            var index = input.startIndex
            while index < input.endIndex {
                let byte = input[index]
                guard RFC_3986.Parse._isRegNameChar(byte) else { break }
                input.formIndex(after: &index)
            }
            host = input[input.startIndex..<index]
            input = input[index...]
        }

        return try _parsePort(&input, userinfo: userinfo, host: host)
    }

    @inlinable
    package func _parsePort(
        _ input: inout Input,
        userinfo: Input?,
        host: Input
    ) throws(Failure) -> Output {
        var port: UInt16? = nil
        if input.startIndex < input.endIndex && input[input.startIndex] == 0x3A {
            input = input[input.index(after: input.startIndex)...]
            var hasDigits = false
            var portValue: UInt16 = 0
            while input.startIndex < input.endIndex {
                let byte = input[input.startIndex]
                guard byte >= 0x30 && byte <= 0x39 else { break }
                hasDigits = true
                let digit = UInt16(byte &- 0x30)
                let (v1, o1) = portValue.multipliedReportingOverflow(by: 10)
                let (v2, o2) = v1.addingReportingOverflow(digit)
                guard !o1 && !o2 else { throw .portOverflow }
                portValue = v2
                input = input[input.index(after: input.startIndex)...]
            }
            if hasDigits {
                port = portValue
            }
        }

        return Output(userinfo: userinfo, host: host, port: port)
    }
}

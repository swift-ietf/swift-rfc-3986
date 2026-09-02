public import ASCII_Serializer
public import Binary_Serializable
public import Parseable_ASCII
import Byte
import Byte_Standard_Library_Integration

extension RFC_3986.URI {

    public struct Query: Sendable, Codable, Hashable, Equatable {

        public let rawValue: String

        public let parameters: [(key: String, value: String?)]

        init(
            __unchecked _: Void,
            rawValue: String,
            parameters: [(key: String, value: String?)]
        ) {
            self.rawValue = rawValue
            self.parameters = parameters
        }
    }
}

extension RFC_3986.URI.Query {

    public typealias RawValue = String
}

extension RFC_3986.URI.Query: Swift.RawRepresentable, ASCII.Serializable, Binary.Serializable {

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

extension RFC_3986.URI.Query: ASCII.Parseable {

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: string.utf8.map(Byte.init(bitPattern:)))
    }

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        if bytes.isEmpty {
            self.init(__unchecked: (), rawValue: "", parameters: [])
            return
        }

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
                    reason: "non-ASCII byte in query"
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

            if code == ASCII.Code.lf || code == ASCII.Code.cr {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte,
                    reason: "Query cannot contain newlines"
                )
            }

            if code == ASCII.Code.numberSign {
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: code.byte,
                    reason: "Query cannot contain '#' (use for fragment instead)"
                )
            }

            i += 1
        }

        let queryString = String(decoding: bytes, as: UTF8.self)

        var parameters: [(String, String?)] = []
        var pairStart = 0

        func parsePair(_ lo: Int, _ hi: Int) throws(Error) {

            var eqIdx: Int? = nil
            for j in lo..<hi where arr[j] == ASCII.Code.equalsSign {
                eqIdx = j
                break
            }

            if let eq = eqIdx {
                let key = String(decoding: arr[lo..<eq].lazy.map(\.underlying), as: UTF8.self)
                guard !key.isEmpty else { throw Error.emptyKey }
                let value = String(
                    decoding: arr[(eq &+ 1)..<hi].lazy.map(\.underlying),
                    as: UTF8.self
                )
                parameters.append((key, value))
            } else {
                let key = String(decoding: arr[lo..<hi].lazy.map(\.underlying), as: UTF8.self)
                guard !key.isEmpty else { throw Error.emptyKey }
                parameters.append((key, nil))
            }
        }

        for idx in 0..<arr.count {
            if arr[idx] == ASCII.Code.ampersand {
                try parsePair(pairStart, idx)
                pairStart = idx &+ 1
            }
        }
        try parsePair(pairStart, arr.count)

        self.init(__unchecked: (), rawValue: queryString, parameters: parameters)
    }
}

extension RFC_3986.URI.Query: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

extension RFC_3986.URI.Query {

    private var _legacyParameters: [(key: String, value: String?)] { parameters }

    public init(_ parameters: [(String, String?)] = []) throws(Error) {

        let queryString = parameters.map { key, value in
            if let value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")

        try self.init(ascii: queryString.utf8.map(Byte.init(bitPattern:)))
    }

    internal init(unchecked parameters: [(String, String?)]) {
        let queryString = parameters.map { key, value in
            if let value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")
        self.init(__unchecked: (), rawValue: queryString, parameters: parameters)
    }

    public var string: String {
        parameters.map { key, value in
            if let value {
                return "\(key)=\(value)"
            } else {
                return key
            }
        }.joined(separator: "&")
    }

    public var isEmpty: Bool {
        parameters.isEmpty
    }

    public var count: Int {
        parameters.count
    }

    public subscript(key: String) -> [String?] {
        parameters.filter { $0.key == key }.map { $0.value }
    }

    public func first(for key: some StringProtocol) -> String? {
        parameters.first { $0.key == key }?.value
    }

    public func appending(
        key: some StringProtocol,
        value: (some StringProtocol)?
    ) throws(Error) -> RFC_3986.URI.Query {
        var newParameters = parameters
        newParameters.append((String(key), value.map { String($0) }))
        return try RFC_3986.URI.Query(newParameters)
    }

    public func removing(key: some StringProtocol) -> RFC_3986.URI.Query {
        let filtered = parameters.filter { $0.key != key }
        return RFC_3986.URI.Query(unchecked: filtered)
    }

    public var keys: Set<String> {
        Set(parameters.map { $0.key })
    }
}

extension RFC_3986.URI.Query: Swift.Collection {
    public typealias Index = Array<(key: String, value: String?)>.Index
    public typealias Element = (key: String, value: String?)

    public var startIndex: Index {
        parameters.startIndex
    }

    public var endIndex: Index {
        parameters.endIndex
    }

    public subscript(position: Index) -> Element {
        parameters[position]
    }

    public func index(after i: Index) -> Index {
        parameters.index(after: i)
    }
}

extension RFC_3986.URI.Query: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: (String, String?)...) {
        self.init(unchecked: elements)
    }
}

extension RFC_3986.URI.Query: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, String)...) {
        self.init(unchecked: elements.map { ($0, $1 as String?) })
    }
}

extension RFC_3986.URI.Query {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    public static func == (lhs: Self, rhs: String) -> Bool {
        lhs.rawValue == rhs
    }
}

extension RFC_3986.URI.Query {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        do throws(Error) {
            try self.init(string)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid query: \(error)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

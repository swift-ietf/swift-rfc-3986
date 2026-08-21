public import ASCII_Serializer_Primitives
public import Binary_Serializable_Primitives
public import Parseable_ASCII_Primitives

extension RFC_3986.URI {

    public struct Path: Sendable, Equatable, Hashable {

        public let segments: [String]

        public let isAbsolute: Bool

        init(
            __unchecked _: Void,
            segments: [String],
            isAbsolute: Bool
        ) {
            self.segments = segments
            self.isAbsolute = isAbsolute
        }
    }
}

extension RFC_3986.URI.Path: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        if value.isAbsolute {
            buffer.append(ASCII.Code.solidus)
        }

        for (index, segment) in value.segments.enumerated() {
            if index > 0 {
                buffer.append(ASCII.Code.solidus)
            }
            for byte in segment.utf8 { buffer.append(ASCII.Code(byte)) }
        }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ path: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        if path.isAbsolute {
            buffer.append(ASCII.Code.solidus)
        }

        for (index, segment) in path.segments.enumerated() {
            if index > 0 {
                buffer.append(ASCII.Code.solidus)
            }
            buffer.append(contentsOf: segment.utf8)
        }
    }
}

extension RFC_3986.URI.Path: ASCII.Parseable {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(Error)
    where Bytes.Element == Byte {

        guard !bytes.isEmpty else {
            self.init(__unchecked: (), segments: [], isAbsolute: false)
            return
        }

        let arr: [ASCII.Code]
        do throws(ASCII.Code.Error) {
            arr = try [ASCII.Code](bytes)
        } catch {
            switch error {
            case .notASCII(let byte):
                throw Error.invalidCharacter(
                    String(decoding: bytes, as: UTF8.self),
                    byte: byte,
                    reason: "non-ASCII byte in path"
                )
            }
        }

        let isAbsolute = arr.first == ASCII.Code.solidus

        if arr.count == 1 && isAbsolute {
            self.init(__unchecked: (), segments: [], isAbsolute: true)
            return
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
                    reason: "Path cannot contain newlines"
                )
            }

            i += 1
        }

        let pathCodes: ArraySlice<ASCII.Code> = isAbsolute ? arr.dropFirst() : arr[...]

        if pathCodes.isEmpty {
            self.init(__unchecked: (), segments: [], isAbsolute: isAbsolute)
            return
        }

        var segments: [String] = []
        var currentSegment: [ASCII.Code] = []

        for code in pathCodes {
            if code == ASCII.Code.solidus {
                segments.append(String(decoding: currentSegment, as: UTF8.self))
                currentSegment = []
            } else {
                currentSegment.append(code)
            }
        }
        segments.append(String(decoding: currentSegment, as: UTF8.self))

        self.init(__unchecked: (), segments: segments, isAbsolute: isAbsolute)
    }
}

extension RFC_3986.URI.Path {

    public init(segments: [String], isAbsolute: Bool = true) throws(Error) {

        for segment in segments {
            if segment.contains("/") {
                throw Error.segmentContainsSeparator(segment)
            }

            if segment.contains(where: { $0.isNewline || ($0.isWhitespace && $0 != " ") }) {
                throw Error.segmentContainsWhitespace(segment)
            }
        }

        self.init(__unchecked: (), segments: segments, isAbsolute: isAbsolute)
    }

    public init(_ string: some StringProtocol) throws(Error) {
        try self.init(ascii: [Byte](string.utf8))
    }
}

extension RFC_3986.URI.Path {

    public var isEmpty: Bool {
        segments.isEmpty
    }

    public var count: Int {
        segments.count
    }

    public func appending(_ segment: some StringProtocol) throws(Error) -> Self {
        var newSegments = segments
        newSegments.append(String(segment))
        return try Self(segments: newSegments, isAbsolute: isAbsolute)
    }

    public func appending(contentsOf segments: [String]) throws(Error) -> Self {
        var newSegments = self.segments
        newSegments.append(contentsOf: segments)
        return try Self(segments: newSegments, isAbsolute: isAbsolute)
    }

    public func deletingLastSegment() -> Self {
        guard !segments.isEmpty else { return self }
        var newSegments = segments
        newSegments.removeLast()
        return Self(__unchecked: (), segments: newSegments, isAbsolute: isAbsolute)
    }

    public var lastSegment: String? {
        segments.last
    }

    public var firstSegment: String? {
        segments.first
    }
}

extension RFC_3986.URI.Path: Swift.Collection {
    public typealias Index = Array<String>.Index
    public typealias Element = String

    public var startIndex: Index {
        segments.startIndex
    }

    public var endIndex: Index {
        segments.endIndex
    }

    public subscript(position: Index) -> String {
        segments[position]
    }

    public func index(after i: Index) -> Index {
        segments.index(after: i)
    }
}

extension RFC_3986.URI.Path: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: String...) {
        self.init(__unchecked: (), segments: elements, isAbsolute: true)
    }
}

extension RFC_3986.URI.Path: CustomStringConvertible {

    public var description: String {
        String(decoding: serialized, as: UTF8.self)
    }
}

extension RFC_3986.URI.Path: Codable {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        do throws(Error) {
            try self.init(string)
        } catch {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid path: \(error)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

extension [Byte] {

    public init(_ path: RFC_3986.URI.Path) {
        var bytes: [Byte] = []

        if path.isAbsolute {
            bytes.append(ASCII.Code.solidus)
        }

        for (index, segment) in path.segments.enumerated() {
            if index > 0 {
                bytes.append(ASCII.Code.solidus)
            }
            bytes.append(contentsOf: segment.utf8)
        }

        self = bytes
    }
}

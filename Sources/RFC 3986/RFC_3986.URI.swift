public import ASCII_Serializer
public import Binary_Serializable
public import Parseable_ASCII

extension RFC_3986 {

    public enum Error: Swift.Error, Hashable, Sendable {

        case invalidURI(String)

        case invalidComponent(String)

        case conversionFailed(String)
    }
}

extension RFC_3986.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidURI(let value):
            return
                "Invalid URI: '\(value)'. URIs must follow RFC 3986 syntax and contain only ASCII characters."

        case .invalidComponent(let component):
            return "Invalid URI component: '\(component)'"

        case .conversionFailed(let reason):
            return "URI conversion failed: \(reason)"
        }
    }
}

extension RFC_3986 {

    public protocol URIRepresentable {

        var uri: RFC_3986.URI { get }
    }
}

extension RFC_3986 {

    public struct URI: Hashable, Sendable, Codable {
        fileprivate let cache: Cache
    }
}

extension RFC_3986.URI {

    public var value: String { cache.value }
}

extension RFC_3986.URI {

    public static func == <S: StringProtocol>(lhs: RFC_3986.URI, rhs: S) -> Bool {
        lhs.value == rhs
    }

    public static func == <S: StringProtocol>(lhs: S, rhs: RFC_3986.URI) -> Bool {
        lhs == rhs.value
    }
}

extension RFC_3986.URI {

    fileprivate final class Cache: @unchecked Sendable {
        let value: String
        let components: ParsedComponents

        let scheme: Scheme?
        let host: Host?
        let port: Port?
        let path: Path?
        let query: Query?
        let fragment: Fragment?

        init(value: String) {
            self.value = value
            let components = Self.parseURI(value)
            self.components = components
            self.scheme = Self.parsed(components.scheme) { try Scheme($0) }
            self.host = Self.parsed(components.host) { try Host($0) }
            self.port = components.port.flatMap { Port($0) }

            self.path = Self.parsed(components.path) { try Path($0) }
            self.query = Self.parsed(components.query) { try Query($0) }
            self.fragment = Self.parsed(components.fragment) { try Fragment($0) }
        }

        init(value: String, components: ParsedComponents) {
            self.value = value
            self.components = components
            self.scheme = Self.parsed(components.scheme) { try Scheme($0) }
            self.host = Self.parsed(components.host) { try Host($0) }
            self.port = components.port.flatMap { Port($0) }
            self.path = Self.parsed(components.path) { try Path($0) }
            self.query = Self.parsed(components.query) { try Query($0) }
            self.fragment = Self.parsed(components.fragment) { try Fragment($0) }
        }

        private static func parsed<Value, Failure: Swift.Error>(
            _ string: String?,
            _ makeValue: (String) throws(Failure) -> Value
        ) -> Value? {
            guard let string else { return nil }
            do throws(Failure) {
                return try makeValue(string)
            } catch {
                return nil
            }
        }
    }
}

extension RFC_3986.URI.Cache {

    struct ParsedComponents {
        let scheme: String?
        let userinfo: String?
        let host: String?
        let port: UInt16?
        let path: String?
        let query: String?
        let fragment: String?
    }

    fileprivate static func parseURI(_ uri: String) -> ParsedComponents {
        var scheme: String?
        var authority: String?
        var path: String?
        var query: String?
        var fragment: String?

        var remaining = uri

        if let fragmentIndex = remaining.lastIndex(of: "#") {
            fragment = String(remaining[remaining.index(after: fragmentIndex)...])
            remaining = String(remaining[..<fragmentIndex])
        }

        if let queryIndex = remaining.lastIndex(of: "?") {
            query = String(remaining[remaining.index(after: queryIndex)...])
            remaining = String(remaining[..<queryIndex])
        }

        if let colonIndex = remaining.firstIndex(of: ":"),
            colonIndex > remaining.startIndex
        {
            let schemeCandidate = String(remaining[..<colonIndex])

            if !schemeCandidate.contains("/") && !schemeCandidate.contains("?")
                && !schemeCandidate.contains("#")
            {
                scheme = schemeCandidate
                remaining = String(remaining[remaining.index(after: colonIndex)...])
            }
        }

        if remaining.hasPrefix("//") {
            let afterSlashes = remaining.index(remaining.startIndex, offsetBy: 2)
            var authorityEnd = remaining.endIndex

            for char in ["/", "?", "#"] {
                if let index = remaining[afterSlashes...].firstIndex(of: Character(char)) {
                    if index < authorityEnd {
                        authorityEnd = index
                    }
                }
            }

            authority = String(remaining[afterSlashes..<authorityEnd])
            remaining = String(remaining[authorityEnd...])
        }

        if !remaining.isEmpty {
            path = remaining
        }

        var userinfo: String?
        var host: String?
        var port: UInt16?
        if let auth = authority {
            (userinfo, host, port) = parseAuthority(auth)
        }

        return ParsedComponents(
            scheme: scheme,
            userinfo: userinfo,
            host: host,
            port: port,
            path: path,
            query: query,
            fragment: fragment
        )
    }

    fileprivate static func parseAuthority(
        _ authority: String
    ) -> (userinfo: String?, host: String?, port: UInt16?) {
        var remaining = authority
        var userinfo: String?

        if let atIndex = remaining.lastIndex(of: "@") {
            userinfo = String(remaining[..<atIndex])
            remaining = String(remaining[remaining.index(after: atIndex)...])
        }

        if let colonIndex = remaining.lastIndex(of: ":") {
            let hostPart = String(remaining[..<colonIndex])
            let portPart = String(remaining[remaining.index(after: colonIndex)...])

            if let portValue = UInt16(portPart) {
                return (userinfo, hostPart.isEmpty ? nil : hostPart, portValue)
            }
        }

        return (userinfo, remaining.isEmpty ? nil : remaining, nil)
    }
}

extension RFC_3986.URI.Cache {

    static func _parseAndValidate(_ string: String) -> ParsedComponents? {

        guard string.utf8.allSatisfy({ $0 < 0x80 }) else { return nil }

        let components = parseURI(string)

        if let scheme = components.scheme {
            guard RFC_3986.Parse._isValidScheme(scheme.utf8) else { return nil }
        }

        if let userinfo = components.userinfo {
            guard
                RFC_3986.Parse._isGrammarValid(
                    userinfo.utf8,
                    allowedRawByte: RFC_3986.Parse._isUserinfoChar
                )
            else { return nil }
        }

        if let host = components.host {
            do throws(RFC_3986.URI.Host.Error) {
                _ = try RFC_3986.URI.Host(host)
            } catch {
                return nil
            }
        }

        if let path = components.path {
            guard
                RFC_3986.Parse._isGrammarValid(
                    path.utf8,
                    allowedRawByte: { RFC_3986.Parse._isPchar($0) || $0 == 0x2F }
                )
            else { return nil }

            if components.scheme == nil, components.host == nil, !path.hasPrefix("/") {
                let firstSegment = path.prefix(while: { $0 != "/" })
                guard !firstSegment.contains(":") else { return nil }
            }
        }

        if let query = components.query {
            guard
                RFC_3986.Parse._isGrammarValid(
                    query.utf8,
                    allowedRawByte: RFC_3986.Parse._isQueryOrFragmentChar
                )
            else { return nil }
        }

        if let fragment = components.fragment {
            guard
                RFC_3986.Parse._isGrammarValid(
                    fragment.utf8,
                    allowedRawByte: RFC_3986.Parse._isQueryOrFragmentChar
                )
            else { return nil }
        }

        return components
    }
}

extension RFC_3986.URI: ASCII.Serializable, Binary.Serializable {

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == ASCII.Code {
        for byte in value.value.utf8 { buffer.append(ASCII.Code(byte)) }
    }

    public static func serialize<Buffer: RangeReplaceableCollection>(
        _ value: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        serializeBytes(value, into: &buffer)
    }

    private static func serializeBytes<Buffer: RangeReplaceableCollection>(
        _ uri: Self,
        into buffer: inout Buffer
    ) where Buffer.Element == Byte {
        buffer.append(contentsOf: uri.value.utf8)
    }
}

extension RFC_3986.URI: ASCII.Parseable {

    public init<Bytes: Swift.Collection>(ascii bytes: Bytes) throws(RFC_3986.Error)
    where Bytes.Element == Byte {
        let string = String(decoding: bytes, as: UTF8.self)
        guard RFC_3986.isValidURI(string) else {
            throw RFC_3986.Error.invalidURI(string)
        }
        self.init(__unchecked: (), value: string)
    }
}

extension RFC_3986.URI {

    public init(_ value: some StringProtocol) throws(RFC_3986.Error) {
        let stringValue = String(value)

        if stringValue.isEmpty {
            self.cache = Cache(value: stringValue)
            return
        }

        guard let components = Cache._parseAndValidate(stringValue) else {
            throw RFC_3986.Error.invalidURI(stringValue)
        }
        self.cache = Cache(value: stringValue, components: components)
    }

    init(
        __unchecked _: Void,
        value: String
    ) {
        self.cache = Cache(value: value)
    }

    public init(unchecked value: String) {
        self.init(__unchecked: (), value: value)
    }

    public init(
        scheme: Scheme,
        authority: Authority,
        path: Path,
        query: Query? = nil,
        fragment: Fragment? = nil
    ) {
        var uriString = "\(scheme.value)://"

        if let userinfo = authority.userinfo {
            uriString += "\(userinfo.rawValue)@"
        }

        uriString += authority.host.rawValue

        if let port = authority.port {
            uriString += ":\(port.value)"
        }

        uriString += path.description

        if let query {
            uriString += "?\(query.description)"
        }

        if let fragment {
            uriString += "#\(fragment.value)"
        }

        self.cache = Cache(value: uriString)
    }
}

extension RFC_3986.URI {

    public var scheme: Scheme? {
        cache.scheme
    }

    public var userinfo: Userinfo? {

        var remaining = cache.value

        if let colonIndex = remaining.firstIndex(of: ":") {
            remaining = String(remaining[remaining.index(after: colonIndex)...])
        }

        guard remaining.hasPrefix("//") else { return nil }
        let afterSlashes = remaining.index(remaining.startIndex, offsetBy: 2)
        var authorityEnd = remaining.endIndex

        for char in ["/", "?", "#"] {
            if let index = remaining[afterSlashes...].firstIndex(of: Character(char)) {
                if index < authorityEnd {
                    authorityEnd = index
                }
            }
        }

        let authority = String(remaining[afterSlashes..<authorityEnd])

        guard let atIndex = authority.firstIndex(of: "@") else { return nil }
        let userinfoString = String(authority[..<atIndex])

        do throws(Userinfo.Error) {
            return try Userinfo(userinfoString)
        } catch {
            return nil
        }
    }

    public var host: Host? {
        cache.host
    }

    public var port: Port? {
        cache.port
    }

    public var path: Path? {
        cache.path
    }

    public var query: Query? {
        cache.query
    }

    public var fragment: Fragment? {
        cache.fragment
    }
}

extension RFC_3986.URI {

    public var isRelative: Bool {
        scheme == nil
    }

    public var isSecure: Bool {
        guard let uriScheme = scheme?.value else { return false }
        return ["https", "wss", "ftps"].contains(uriScheme)
    }

    public var isHTTP: Bool {
        guard let uriScheme = scheme?.value else { return false }
        return uriScheme == "http" || uriScheme == "https"
    }

    public var base: RFC_3986.URI? {
        guard let uriScheme = scheme,
            let uriHost = host
        else { return nil }

        var baseString = "\(uriScheme.value)://\(uriHost.rawValue)"
        if let uriPort = port {
            baseString += ":\(uriPort.value)"
        }
        return RFC_3986.URI(unchecked: baseString)
    }

    public var pathAndQuery: String? {
        guard let uriPath = path else { return nil }
        if let uriQuery = query {
            return "\(uriPath.description)?\(uriQuery.description)"
        }
        return uriPath.description
    }
}

extension RFC_3986.URI {

    public func normalized() -> RFC_3986.URI {

        let normalizedScheme = scheme?.value.lowercased()
        let normalizedHost = host?.rawValue.lowercased()
        var normalizedPort = port
        var normalizedPath = path?.description
        var normalizedQuery = query?.description
        let normalizedFragment = fragment?.value

        if let scheme = normalizedScheme, let port = normalizedPort {
            let isDefaultPort =
                (scheme == "http" && port == 80) || (scheme == "https" && port == 443)
                || (scheme == "ftp" && port == 21)
            if isDefaultPort {
                normalizedPort = nil
            }
        }

        if let pathString = normalizedPath, !pathString.isEmpty {
            normalizedPath = RFC_3986.removeDotSegments(from: pathString)
        }

        if let pathString = normalizedPath {
            normalizedPath = RFC_3986.normalizePercentEncoding(pathString)
        }
        if let queryString = normalizedQuery {
            normalizedQuery = RFC_3986.normalizePercentEncoding(queryString)
        }

        var result = ""
        if let scheme = normalizedScheme {
            result += "\(scheme):"
        }
        if let host = normalizedHost {
            result += "//\(host)"
            if let port = normalizedPort {
                result += ":\(port)"
            }
        }
        if let path = normalizedPath {
            result += path
        }
        if let query = normalizedQuery {
            result += "?\(query)"
        }
        if let fragment = normalizedFragment {
            result += "#\(fragment)"
        }

        return RFC_3986.URI(unchecked: result)
    }

    public func normalizePercentEncoding() -> RFC_3986.URI {
        var normalizedPath = path?.description
        var normalizedQuery = query?.description

        if let pathString = normalizedPath {
            normalizedPath = RFC_3986.normalizePercentEncoding(pathString)
        }

        if let queryString = normalizedQuery {
            normalizedQuery = RFC_3986.normalizePercentEncoding(queryString)
        }

        var result = ""
        if let scheme = scheme?.value {
            result += "\(scheme):"
        }

        if let host = host?.rawValue {
            result += "//"
            if let userinfo = userinfo?.rawValue {
                result += "\(userinfo)@"
            }
            result += host
            if let port {
                result += ":\(port)"
            }
        }

        if let path = normalizedPath {
            result += path
        }
        if let query = normalizedQuery {
            result += "?\(query)"
        }
        if let fragment = fragment?.value {
            result += "#\(fragment)"
        }

        return RFC_3986.URI(unchecked: result)
    }

    public func resolve(_ reference: RFC_3986.URI) throws(RFC_3986.Error) -> RFC_3986.URI {
        try resolve(reference.value)
    }

    public func resolve(_ reference: some StringProtocol) throws(RFC_3986.Error) -> RFC_3986.URI {

        let refURI = try RFC_3986.URI(reference)

        if refURI.scheme != nil {
            return refURI
        }

        if refURI.host != nil {
            var result = ""
            if let baseScheme = scheme {
                result += "\(baseScheme.value):"
            }
            result += "//"
            if let refHost = refURI.host {
                result += refHost.rawValue
            }
            if let refPort = refURI.port {
                result += ":\(refPort)"
            }
            if let refPath = refURI.path {
                result += refPath.description
            }
            if let refQuery = refURI.query {
                result += "?\(refQuery.description)"
            }
            if let refFragment = refURI.fragment {
                result += "#\(refFragment.value)"
            }
            return RFC_3986.URI(unchecked: result)
        }

        var result = ""
        if let baseScheme = scheme {
            result += "\(baseScheme.value):"
        }
        if let baseHost = host {
            result += "//\(baseHost.rawValue)"
            if let basePort = port {
                result += ":\(basePort)"
            }
        }

        let refPath = refURI.path?.description
        var mergedPath = ""
        if let refPath, !refPath.isEmpty {
            if refPath.hasPrefix("/") {

                mergedPath = refPath
            } else {

                if let basePath = path?.description {

                    if let lastSlash = basePath.lastIndex(of: "/") {
                        mergedPath = String(basePath[...lastSlash]) + refPath
                    } else {
                        mergedPath = refPath
                    }
                } else {
                    mergedPath = "/\(refPath)"
                }
            }

            mergedPath = RFC_3986.removeDotSegments(from: mergedPath)
            result += mergedPath
        } else if let basePath = path {
            result += basePath.description
        }

        if let refQuery = refURI.query {
            result += "?\(refQuery.description)"
        } else if refPath == nil, let baseQuery = query {
            result += "?\(baseQuery.description)"
        }

        if let refFragment = refURI.fragment {
            result += "#\(refFragment.value)"
        }

        return RFC_3986.URI(unchecked: result)
    }
}

extension RFC_3986.URI {

    public func appendingPathComponent(_ component: some StringProtocol) -> RFC_3986.URI {
        var result = ""

        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        let encodedComponent = RFC_3986.percentEncode(String(component), allowing: .pathSegment)

        let currentPath = path?.description ?? ""
        let separator = currentPath.hasSuffix("/") ? "" : "/"
        result += currentPath + separator + encodedComponent

        if let uriQuery = query {
            result += "?\(uriQuery.description)"
        }
        if let uriFragment = fragment {
            result += "#\(uriFragment.value)"
        }

        return RFC_3986.URI(unchecked: result)
    }

    public func appendingQueryItem(
        name: some StringProtocol,
        value: (some StringProtocol)?
    ) -> RFC_3986.URI {
        var result = ""

        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        if let uriPath = path {
            result += uriPath.description
        }

        let encodedName = RFC_3986.percentEncode(String(name), allowing: .queryComponent)
        let encodedValue = value.map {
            RFC_3986.percentEncode(String($0), allowing: .queryComponent)
        }

        if let currentQuery = query?.description {
            result += "?\(currentQuery)&\(encodedName)"
            if let value = encodedValue {
                result += "=\(value)"
            }
        } else {
            result += "?\(encodedName)"
            if let value = encodedValue {
                result += "=\(value)"
            }
        }

        if let uriFragment = fragment {
            result += "#\(uriFragment.value)"
        }

        return RFC_3986.URI(unchecked: result)
    }

    public func settingFragment(_ fragment: Fragment?) -> RFC_3986.URI {
        var result = ""

        if let uriScheme = scheme {
            result += "\(uriScheme.value):"
        }

        if let uriHost = host {
            result += "//\(uriHost.rawValue)"
            if let uriPort = port {
                result += ":\(uriPort)"
            }
        }

        if let uriPath = path {
            result += uriPath.description
        }

        if let uriQuery = query {
            result += "?\(uriQuery.description)"
        }

        if let newFragment = fragment {
            result += "#\(newFragment.value)"
        }

        return RFC_3986.URI(unchecked: result)
    }
}

extension RFC_3986.URI {

    public static func == (lhs: RFC_3986.URI, rhs: RFC_3986.URI) -> Bool {
        lhs.value == rhs.value
    }
}

extension RFC_3986.URI {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
}

extension RFC_3986.URI {

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

extension RFC_3986.URI {

    public static func / (
        base: RFC_3986.URI,
        reference: String
    ) throws(RFC_3986.Error) -> RFC_3986.URI {
        try base.resolve(reference)
    }

    public static func / (
        base: RFC_3986.URI,
        reference: RFC_3986.URI
    ) throws(RFC_3986.Error) -> RFC_3986.URI {
        try base.resolve(reference)
    }
}

extension RFC_3986.URI {

    public typealias Representable = RFC_3986.URIRepresentable
}

extension RFC_3986.URI: RFC_3986.URIRepresentable {
    public var uri: RFC_3986.URI {
        self
    }
}

extension RFC_3986.URI: CustomStringConvertible {
    public var description: String {
        value
    }
}

extension RFC_3986.URI: CustomDebugStringConvertible {
    public var debugDescription: String {
        var parts: [String] = ["RFC 3986.URI"]

        if let scheme {
            parts.append("scheme: \(scheme)")
        }
        if let host {
            parts.append("host: \(host)")
        }
        if let port {
            parts.append("port: \(port)")
        }
        if let path, !path.isEmpty {
            parts.append("path: \(path)")
        }
        if let query {
            parts.append("query: \(query)")
        }
        if let fragment {
            parts.append("fragment: \(fragment)")
        }

        return parts.joined(separator: ", ")
    }
}

extension RFC_3986.URI: Comparable {

    public static func < (lhs: RFC_3986.URI, rhs: RFC_3986.URI) -> Bool {
        lhs.value < rhs.value
    }
}

extension RFC_3986 {

    public static func removeDotSegments(from path: String) -> String {
        var input = path
        var output = ""

        while !input.isEmpty {

            if input.hasPrefix("../") {
                input.removeFirst(3)
            } else if input.hasPrefix("./") {
                input.removeFirst(2)
            }

            else if input.hasPrefix("/./") {
                input = "/" + input.dropFirst(3)
            } else if input == "/." {
                input = "/"
            }

            else if input.hasPrefix("/../") {
                input = "/" + input.dropFirst(4)

                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            } else if input == "/.." {
                input = "/"
                if let lastSlash = output.lastIndex(of: "/") {
                    output = String(output[..<lastSlash])
                }
            }

            else if input == "." || input == ".." {
                input = ""
            }

            else {

                let startIndex = input.index(after: input.startIndex)
                if let slashIndex = input[startIndex...].firstIndex(of: "/") {
                    let segment = String(input[..<slashIndex])
                    output += segment
                    input = String(input[slashIndex...])
                } else {
                    output += input
                    input = ""
                }
            }
        }

        return output
    }

}

extension RFC_3986 {

    public static func isValidURI(_ string: String) -> Bool {

        if string.isEmpty { return true }

        return RFC_3986.URI.Cache._parseAndValidate(string) != nil
    }

    public static func isValidHTTP<Representable: URIRepresentable>(_ uri: Representable) -> Bool {
        guard let scheme = uri.uri.scheme else { return false }
        return scheme.value == "http" || scheme.value == "https"
    }

    public static func isValidHTTP(_ string: String) -> Bool {
        guard isValidURI(string) else { return false }
        let uri: URI
        do throws(RFC_3986.Error) {
            uri = try URI(string)
        } catch {
            return false
        }
        return uri.scheme?.value == "http" || uri.scheme?.value == "https"
    }
}

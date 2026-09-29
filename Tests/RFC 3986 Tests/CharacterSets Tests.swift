import Testing

@testable import RFC_3986

@Suite
struct `Character Sets` {

    @Test
    func `Unreserved characters`() {
        let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
        for char in unreserved {
            #expect(RFC_3986.CharacterSet.unreserved.contains(char))
        }
    }

    @Test
    func `Reserved characters`() {
        let reserved = ":/?#[]@!$&'()*+,;="
        for char in reserved {
            #expect(RFC_3986.CharacterSet.reserved.contains(char))
        }
    }

    @Test
    func `General delimiters`() {
        let genDelims = ":/?#[]@"
        for char in genDelims {
            #expect(RFC_3986.CharacterSet.genDelims.contains(char))
        }
    }

    @Test
    func `Sub-delimiters`() {
        let subDelims = "!$&'()*+,;="
        for char in subDelims {
            #expect(RFC_3986.CharacterSet.subDelims.contains(char))
        }
    }
}

@Suite
struct `CharacterSet SetAlgebra Conformance` {

    @Test
    func `CharacterSet union()`() {
        let combined = RFC_3986.CharacterSet.unreserved.union(.reserved)

        #expect(combined.contains("a"))
        #expect(combined.contains("-"))

        #expect(combined.contains(":"))
        #expect(combined.contains("/"))
    }

    @Test
    func `CharacterSet intersection()`() {

        let intersection = RFC_3986.CharacterSet.reserved.intersection(.genDelims)

        #expect(intersection.contains(":"))
        #expect(intersection.contains("/"))

        #expect(!intersection.contains("!"))
        #expect(!intersection.contains("$"))
    }

    @Test
    func `CharacterSet symmetricDifference()`() {
        let diff = RFC_3986.CharacterSet.genDelims.symmetricDifference(.subDelims)

        #expect(diff.contains(":"))
        #expect(diff.contains("/"))

        #expect(diff.contains("!"))
        #expect(diff.contains("$"))

        #expect(!diff.contains("x"))
    }

    @Test
    func `CharacterSet empty init`() {
        let empty = RFC_3986.CharacterSet()
        #expect(!empty.contains("a"))
        #expect(!empty.contains(":"))
        #expect(!empty.contains(" "))
    }

    @Test
    func `CharacterSet mutating operations`() {
        var mutableSet = RFC_3986.CharacterSet.unreserved

        let (inserted, _) = mutableSet.insert("🔥")
        #expect(inserted)
        #expect(mutableSet.contains("🔥"))

        let removed = mutableSet.remove("🔥")
        #expect(removed == "🔥")
        #expect(!mutableSet.contains("🔥"))
    }
}

@Suite
struct `URI Resolution - RFC 3986 Section 5.4` {

    let base = "http://a/b/c/d;p?q"

    @Test
    func `Normal examples - absolute URI`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "g:h"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "g:h")
    }

    @Test
    func `Normal examples - relative path`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/b/c/g")
    }

    @Test
    func `Normal examples - relative path with ./`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "./g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/b/c/g")
    }

    @Test
    func `Normal examples - absolute path`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "/g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/g")
    }

    @Test
    func `Normal examples - network path`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "//g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value.contains("//g"))
    }

    @Test
    func `Normal examples - query`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "?y"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/b/c/d;p?y")
    }

    @Test
    func `Normal examples - fragment`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "#s"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value.contains("#s"))
    }

    @Test
    func `Abnormal examples - parent directory`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "../g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/b/g")
    }

    @Test
    func `Abnormal examples - multiple parent directories`() throws {
        let baseURI = try RFC_3986.URI(base)
        let reference = "../../g"
        let resolved = try baseURI.resolve(reference)
        #expect(resolved.value == "http://a/g")
    }

    @Test
    func `Check if URI is relative`() throws {
        let string = "https://example.com/path"
        let absoluteURI = try RFC_3986.URI(string)
        #expect(!absoluteURI.isRelative)

        let relativeString = "/path/to/resource"
        let relativeURI = try RFC_3986.URI(relativeString)
        #expect(relativeURI.isRelative)
        #expect(relativeURI.scheme == nil)
    }
}

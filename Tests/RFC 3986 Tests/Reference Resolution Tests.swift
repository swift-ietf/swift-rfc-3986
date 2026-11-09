import Testing

@testable import RFC_3986

enum `Reference Resolution Tests` {}

extension `Reference Resolution Tests` {
    @Suite
    struct `RFC 3986 Section 5.4 vectors` {

        static let base = "http://a/b/c/d;p?q"

        static let normal: [(String, String)] = [
            ("g:h", "g:h"),
            ("g", "http://a/b/c/g"),
            ("./g", "http://a/b/c/g"),
            ("g/", "http://a/b/c/g/"),
            ("/g", "http://a/g"),
            ("//g", "http://g"),
            ("?y", "http://a/b/c/d;p?y"),
            ("g?y", "http://a/b/c/g?y"),
            ("#s", "http://a/b/c/d;p?q#s"),
            ("g#s", "http://a/b/c/g#s"),
            ("g?y#s", "http://a/b/c/g?y#s"),
            (";x", "http://a/b/c/;x"),
            ("g;x", "http://a/b/c/g;x"),
            ("g;x?y#s", "http://a/b/c/g;x?y#s"),
            ("", "http://a/b/c/d;p?q"),
            (".", "http://a/b/c/"),
            ("./", "http://a/b/c/"),
            ("..", "http://a/b/"),
            ("../", "http://a/b/"),
            ("../g", "http://a/b/g"),
            ("../..", "http://a/"),
            ("../../", "http://a/"),
            ("../../g", "http://a/g"),
        ]

        static let abnormal: [(String, String)] = [
            ("../../../g", "http://a/g"),
            ("../../../../g", "http://a/g"),
            ("/./g", "http://a/g"),
            ("/../g", "http://a/g"),
            ("g.", "http://a/b/c/g."),
            (".g", "http://a/b/c/.g"),
            ("g..", "http://a/b/c/g.."),
            ("..g", "http://a/b/c/..g"),
            ("./../g", "http://a/b/g"),
            ("./g/.", "http://a/b/c/g/"),
            ("g/./h", "http://a/b/c/g/h"),
            ("g/../h", "http://a/b/c/h"),
            ("g;x=1/./y", "http://a/b/c/g;x=1/y"),
            ("g;x=1/../y", "http://a/b/c/y"),
            ("g?y/./x", "http://a/b/c/g?y/./x"),
            ("g?y/../x", "http://a/b/c/g?y/../x"),
            ("g#s/./x", "http://a/b/c/g#s/./x"),
            ("g#s/../x", "http://a/b/c/g#s/../x"),
            ("http:g", "http:g"),
        ]

        @Test(arguments: normal)
        func `Normal examples resolve as section 5.4.1 states`(reference: String, expected: String) throws {
            #expect(try RFC_3986.URI(Self.base).resolve(reference).value == expected)
        }

        @Test(arguments: abnormal)
        func `Abnormal examples resolve as section 5.4.2 states`(reference: String, expected: String) throws {
            #expect(try RFC_3986.URI(Self.base).resolve(reference).value == expected)
        }
    }
}

extension `Reference Resolution Tests` {
    @Suite
    struct `Merging and removing dot segments` {

        @Test
        func `A relative path against an authority with an empty path gains a leading slash`() throws {
            #expect(try RFC_3986.URI("http://a").resolve("g").value == "http://a/g")
        }

        @Test
        func `A reference with a scheme has its dot segments removed`() throws {
            #expect(try RFC_3986.URI("http://a/b").resolve("http://x/a/../b").value == "http://x/b")
        }

        @Test
        func `An empty authority is kept`() throws {
            #expect(try RFC_3986.URI("file:///x/y").resolve("z").value == "file:///x/z")
        }

        @Test
        func `A relative path climbing past its first segment empties the output`() {
            #expect(RFC_3986.removeDotSegments(fromText: "a/../b") == "/b")
            #expect(RFC_3986.removeDotSegments(fromText: "a/..") == "/")
        }
    }
}

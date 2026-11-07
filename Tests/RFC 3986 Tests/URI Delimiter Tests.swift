import Testing

@testable import RFC_3986

enum `URI Delimiter Tests` {}

extension `URI Delimiter Tests` {
    /// RFC 3986 section 3 and Appendix B: the query starts at the first `?` before the first `#`,
    /// and the fragment starts at the first `#`.
    @Suite
    struct `URI delimiters` {

        @Test(arguments: [
            ("/a?b?c", "/a", "b?c"),
            ("/a??", "/a", "?"),
            ("/nl/apps?q=wat?", "/nl/apps", "q=wat?"),
            ("/nl/statute?q=a?b", "/nl/statute", "q=a?b"),
            ("a?b:c?d", "a", "b:c?d"),
        ])
        func `The query starts at the first question mark`(
            input: String,
            expectedPath: String,
            expectedQuery: String
        ) throws {
            let uri = try RFC_3986.URI(input)
            #expect(uri.path?.description == expectedPath)
            #expect(uri.query?.description == expectedQuery)
            #expect(uri.fragment == nil)
            #expect(uri.value == input)
        }

        @Test
        func `A question mark in a query stays in its parameter`() throws {
            let uri = try RFC_3986.URI("/nl/apps?q=wat?&r=s?t")
            #expect(uri.query?.first(for: "q") == "wat?")
            #expect(uri.query?.first(for: "r") == "s?t")
        }

        @Test
        func `A URI with only a query keeps later question marks in it`() throws {
            let uri = try RFC_3986.URI("??")
            #expect(uri.path == nil)
            #expect(uri.query?.description == "?")
        }

        @Test
        func `Every component around repeated question marks`() throws {
            let uri = try RFC_3986.URI("https://example.com/a?b?c#d?e")
            #expect(uri.scheme?.value == "https")
            #expect(uri.host == .registeredName("example.com"))
            #expect(uri.path?.description == "/a")
            #expect(uri.query?.description == "b?c")
            #expect(uri.fragment?.value == "d?e")
            #expect(uri.pathAndQuery == "/a?b?c")
        }

        @Test
        func `A question mark ends the authority and starts the query`() throws {
            let uri = try RFC_3986.URI("https://example.com?a?b")
            #expect(uri.host == .registeredName("example.com"))
            #expect(uri.path == nil)
            #expect(uri.query?.description == "a?b")
        }

        @Test(arguments: [
            ("/a#b?c", "/a" as String?, "b?c"),
            ("#b?c", nil as String?, "b?c"),
            ("#?", nil as String?, "?"),
        ])
        func `A question mark after the first hash is in the fragment and starts no query`(
            input: String,
            expectedPath: String?,
            expectedFragment: String
        ) throws {
            let uri = try RFC_3986.URI(input)
            #expect(uri.path?.description == expectedPath)
            #expect(uri.query == nil)
            #expect(uri.fragment?.value == expectedFragment)
        }

        @Test
        func `A query ends at the first hash`() throws {
            let uri = try RFC_3986.URI("/a?b?c#d")
            #expect(uri.query?.description == "b?c")
            #expect(uri.fragment?.value == "d")
        }

        @Test(arguments: ["/a#b#c", "/a?b#c#d", "#b#c", "https://example.com/a?b#c#d"])
        func `The fragment grammar refuses a second hash`(input: String) {
            #expect(!RFC_3986.isValidURI(input))
            #expect(throws: RFC_3986.Error.invalidURI(input)) {
                try RFC_3986.URI(input)
            }
        }

        /// `c#d` is the fragment Appendix B's expression selects, and `Fragment` refuses it, as it
        /// refuses every `#`, so the accessor is nil. What must hold is that it costs the path and
        /// query nothing, and that no part of it is taken for the fragment.
        @Test
        func `An unchecked second hash splits at the first and has no valid fragment`() {
            let uri = RFC_3986.URI(unchecked: "/a?b#c#d")
            #expect(uri.path?.description == "/a")
            #expect(uri.query?.description == "b")
            #expect(uri.fragment == nil)
            #expect(uri.value == "/a?b#c#d")
        }

        @Test
        func `An unchecked URI splits at the first question mark`() {
            let uri = RFC_3986.URI(unchecked: "/a?b?c")
            #expect(uri.path?.description == "/a")
            #expect(uri.query?.description == "b?c")
        }

        @Test
        func `A reference with repeated question marks resolves with its whole query`() throws {
            let base = try RFC_3986.URI("https://example.com/a/b")
            #expect(try base.resolve("c?d?e").value == "https://example.com/a/c?d?e")
        }

        @Test(arguments: ["/a?b://u@h", "/a#b://u@h", "/a://u@h", "?b://u@h", "#b://u@h"])
        func `Userinfo-shaped text outside an authority is not userinfo`(input: String) throws {
            let uri = try RFC_3986.URI(input)
            #expect(uri.host == nil)
            #expect(uri.userinfo == nil)
        }

        @Test(arguments: [
            ("https://u@h/a?b://v@w", "u"),
            ("https://u:p@h#b://v@w", "u:p"),
            ("//u@h/a", "u"),
            ("//u:p@h/a", "u:p"),
        ])
        func `Userinfo comes from the authority`(input: String, expected: String) throws {
            let uri = try RFC_3986.URI(input)
            #expect(uri.host == .registeredName("h"))
            #expect(uri.userinfo?.rawValue == expected)
        }

        @Test
        func `Normalizing keeps a repeated question mark in the query`() throws {
            let uri = try RFC_3986.URI("HTTPS://EXAMPLE.COM/a?b?c")
            #expect(uri.normalized().value == "https://example.com/a?b?c")
        }
    }
}

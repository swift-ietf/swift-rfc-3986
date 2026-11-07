import Testing

@testable import RFC_3986

enum `Set Character Tests` {}

extension `Set Character Tests` {
    @Suite
    struct `Set<Character> uri namespace` {

        @Test
        func `URI namespace syntax works`() {

            let reserved: Set<Character> = .uri.reserved
            #expect(reserved.contains(":"))
            #expect(reserved.contains("/"))

            let unreserved: Set<Character> = .uri.unreserved
            #expect(unreserved.contains("a"))
            #expect(unreserved.contains("-"))

            let query: Set<Character> = .uri.query
            #expect(query.contains("?"))
            #expect(query.contains("&"))
        }
    }
}

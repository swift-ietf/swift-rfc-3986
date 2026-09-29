import Testing

@testable import RFC_3986

@Suite
struct `Reading URI components concurrently` {

    struct Components: Equatable, Sendable {
        let scheme: String?
        let host: String?
        let port: UInt16?
        let path: String?
        let query: String?
        let fragment: String?
    }

    @Test
    func `Concurrent reads of every component agree`() async throws {
        let uri = try RFC_3986.URI("https://user@example.com:8080/path/to/thing?key=value#frag")

        let readings = await withTaskGroup(of: Components.self, returning: [Components].self) { group in
            for _ in 0..<2_000 {
                group.addTask {
                    Components(
                        scheme: uri.scheme?.value,
                        host: uri.host?.registeredNameValue,
                        port: uri.port?.value,
                        path: uri.path?.description,
                        query: uri.query?.description,
                        fragment: uri.fragment?.value
                    )
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }

        #expect(readings.count == 2_000)
        #expect(
            readings.allSatisfy {
                $0 == Components(
                    scheme: "https",
                    host: "example.com",
                    port: 8080,
                    path: "/path/to/thing",
                    query: "key=value",
                    fragment: "frag"
                )
            }
        )
    }
}

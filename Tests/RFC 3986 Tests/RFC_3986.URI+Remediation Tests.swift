import Dispatch
import Synchronization
import Testing

@testable import RFC_3986

extension RFC_3986.URI {
    @Suite
    struct Remediation {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

extension RFC_3986.URI.Remediation.Unit {

    @Test
    func `Concurrent first access to cached components does not race`() throws {
        let uri = try RFC_3986.URI(
            "https://user@example.com:8080/path/to/thing?key=value#frag"
        )

        typealias Snapshot = (
            scheme: String?, host: String?, port: UInt16?,
            path: String?, query: String?, fragment: String?
        )

        let iterations = 2_000
        let snapshots = Mutex<[Snapshot]>([])
        snapshots.withLock { $0.reserveCapacity(iterations) }

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            let snapshot: Snapshot = (
                uri.scheme?.value,
                uri.host?.rawValue,
                uri.port?.value,
                uri.path?.description,
                uri.query?.description,
                uri.fragment?.value
            )
            snapshots.withLock { $0.append(snapshot) }
        }

        let expected: Snapshot = (
            "https", "example.com", 8080, "/path/to/thing", "key=value", "frag"
        )

        let collected = snapshots.withLock { $0 }
        #expect(collected.count == iterations)
        for snapshot in collected {
            #expect(snapshot.scheme == expected.scheme)
            #expect(snapshot.host == expected.host)
            #expect(snapshot.port == expected.port)
            #expect(snapshot.path == expected.path)
            #expect(snapshot.query == expected.query)
            #expect(snapshot.fragment == expected.fragment)
        }
    }
}

extension RFC_3986.URI.Remediation.Unit {

    @Test
    func `appendingPathComponent percent-encodes structural characters in the component`() throws {
        let base = try RFC_3986.URI("https://example.com/api")
        let appended = base.appendingPathComponent("../../etc/passwd?x=1#y")

        #expect(appended.value == "https://example.com/api/..%2F..%2Fetc%2Fpasswd%3Fx=1%23y")
        #expect(appended.path?.description == "/api/..%2F..%2Fetc%2Fpasswd%3Fx=1%23y")
        #expect(appended.query == nil)
        #expect(appended.fragment == nil)
    }

    @Test
    func `appendingQueryItem percent-encodes structural characters in name and value`() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let appended = base.appendingQueryItem(name: "a", value: "1&admin=true#frag")

        #expect(appended.query?.description == "a=1%26admin%3Dtrue%23frag")
        #expect(appended.fragment == nil)
    }

    @Test
    func `appendingQueryItem percent-encodes structural characters in the name`() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let appended = base.appendingQueryItem(name: "a&injected=1", value: "x")

        #expect(appended.query?.description == "a%26injected%3D1=x")
    }
}

extension RFC_3986.URI.Remediation.`Edge Case` {

    @Test
    func `isValidURI rejects malformed percent-encoding that the blocklist allowed`() {
        #expect(!RFC_3986.isValidURI("http://example.com/100%offsale"))
    }

    @Test
    func `isValidURI rejects a colon folded into host by an unparseable port`() {
        #expect(!RFC_3986.isValidURI("http://example.com:notaport/path"))
    }

    @Test
    func `URI init throws for the same grammar violations isValidURI rejects`() {
        #expect(throws: RFC_3986.Error.self) {
            try RFC_3986.URI("http://example.com/100%offsale")
        }
        #expect(throws: RFC_3986.Error.self) {
            try RFC_3986.URI("http://example.com:notaport/path")
        }
    }
}

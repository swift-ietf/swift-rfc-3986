import Dispatch
import Testing

@testable import RFC_3986

/// Fable-448 wave-1 remediation regression suite for `RFC_3986.URI`.
///
/// Each test below corresponds to a CONFIRMED, in-scope finding fixed on this
/// branch and is written to fail against the pre-fix source and pass against
/// the post-fix source (see `O/remediation/swift-rfc-3986/REPORT.md` for the
/// captured before/after `swift test` output).
extension RFC_3986.URI {
    @Suite("Remediation")
    struct Remediation {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
    }
}

// MARK: - F-001 — Cache concurrency (blocker)

extension RFC_3986.URI.Remediation.Unit {
    /// F-001: `URI.Cache`'s components were `lazy var`s guarded by nothing —
    /// `lazy` in Swift is not thread-safe, so many tasks racing on first
    /// access to a freshly constructed, shared `URI`'s components could
    /// observe torn/inconsistent state or trigger the initializer expression
    /// concurrently (undefined behavior on a type declared `@unchecked
    /// Sendable`). Post-fix, every component is computed once, eagerly, in
    /// `Cache.init` as an immutable `let`, so every task must observe the
    /// exact same fully-formed value.
    @Test
    func `Concurrent first access to cached components does not race`() throws {
        let uri = try RFC_3986.URI(
            "https://user@example.com:8080/path/to/thing?key=value#frag"
        )

        typealias Snapshot = (
            scheme: String?, host: String?, port: UInt16?,
            path: String?, query: String?, fragment: String?
        )

        // `DispatchQueue.concurrentPerform` fans out onto the real OS thread
        // pool (unlike a `Task` group, which can serialize task start-up on
        // its cooperative pool) to maximize genuine simultaneous first-access
        // contention on `uri`'s cached components.
        let iterations = 2_000
        let mutex = DispatchSemaphore(value: 1)
        var snapshots: [Snapshot] = []
        snapshots.reserveCapacity(iterations)

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            let snapshot: Snapshot = (
                uri.scheme?.value,
                uri.host?.rawValue,
                uri.port?.value,
                uri.path?.description,
                uri.query?.description,
                uri.fragment?.value
            )
            mutex.wait()
            snapshots.append(snapshot)
            mutex.signal()
        }

        let expected: Snapshot = (
            "https", "example.com", 8080, "/path/to/thing", "key=value", "frag"
        )

        #expect(snapshots.count == iterations)
        for snapshot in snapshots {
            #expect(snapshot.scheme == expected.scheme)
            #expect(snapshot.host == expected.host)
            #expect(snapshot.port == expected.port)
            #expect(snapshot.path == expected.path)
            #expect(snapshot.query == expected.query)
            #expect(snapshot.fragment == expected.fragment)
        }
    }
}

// MARK: - F-012 — structure injection via appendingPathComponent / appendingQueryItem (high)

extension RFC_3986.URI.Remediation.Unit {
    /// F-012: `appendingPathComponent` concatenated the caller-supplied
    /// component into the path with no encoding at all, so an unencoded "/",
    /// "?", or "#" in `component` could inject extra path segments, a query,
    /// or a fragment into a URI the caller had already validated.
    @Test
    func `appendingPathComponent percent-encodes structural characters in the component`() throws {
        let base = try RFC_3986.URI("https://example.com/api")
        let appended = base.appendingPathComponent("../../etc/passwd?x=1#y")

        #expect(appended.value == "https://example.com/api/..%2F..%2Fetc%2Fpasswd%3Fx=1%23y")
        #expect(appended.path?.description == "/api/..%2F..%2Fetc%2Fpasswd%3Fx=1%23y")
        #expect(appended.query == nil)
        #expect(appended.fragment == nil)
    }

    /// F-012: `appendingQueryItem` encoded name/value with `.query`, which
    /// (via `sub-delims`) still permits raw "&" and "=" — so a caller-supplied
    /// value could terminate its own pair and inject an additional
    /// `name=value` pair into the query.
    @Test
    func `appendingQueryItem percent-encodes structural characters in name and value`() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let appended = base.appendingQueryItem(name: "a", value: "1&admin=true#frag")

        #expect(appended.query?.description == "a=1%26admin%3Dtrue%23frag")
        #expect(appended.fragment == nil)
    }

    /// F-012: injection also applies to the query item *name*, not just the
    /// value.
    @Test
    func `appendingQueryItem percent-encodes structural characters in the name`() throws {
        let base = try RFC_3986.URI("https://example.com/path")
        let appended = base.appendingQueryItem(name: "a&injected=1", value: "x")

        #expect(appended.query?.description == "a%26injected%3D1=x")
    }
}

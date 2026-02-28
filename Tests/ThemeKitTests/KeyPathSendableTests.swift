import Testing
@testable import ThemeKit

@Suite("KeyPath+Sendable")
struct KeyPathSendableTests {

    // MARK: - Compile-time Sendable conformance

    /// Helper that requires its argument to be Sendable.
    /// If KeyPath did not conform to Sendable, calls to this function
    /// with KeyPath arguments would fail to compile.
    private func requireSendable<T: Sendable>(_ value: T) -> T { value }

    @Test func keyPath_withSendableRootAndValue_conformsToSendable() {
        // SendableRoot and SendableValue are both Sendable,
        // so KeyPath<SendableRoot, String> should satisfy Sendable.
        let kp = requireSendable(\SendableRoot.name)
        #expect(kp == \SendableRoot.name)
    }

    @Test func keyPath_nestedProperty_conformsToSendable() {
        let kp = requireSendable(\SendableRoot.count)
        #expect(kp == \SendableRoot.count)
    }

    // MARK: - Cross-actor sending

    private actor Collector {
        func read<Root: Sendable, Value: Sendable>(
            _ keyPath: KeyPath<Root, Value>, from root: Root
        ) -> Value {
            root[keyPath: keyPath]
        }
    }

    @Test func keyPath_canBeSentAcrossActorBoundary() async {
        let collector = Collector()
        let root = SendableRoot(name: "theme", count: 42)

        let name = await collector.read(\.name, from: root)
        let count = await collector.read(\.count, from: root)

        #expect(name == "theme")
        #expect(count == 42)
    }

    // MARK: - Sendable closure capture

    @Test func keyPath_canBeCapturedInSendableClosure() async {
        let kp: KeyPath<SendableRoot, String> = \.name
        let root = SendableRoot(name: "captured", count: 0)

        let result = await Task { @Sendable in
            root[keyPath: kp]
        }.value

        #expect(result == "captured")
    }
}

// MARK: - Test helpers

private struct SendableRoot: Sendable {
    let name: String
    let count: Int
}

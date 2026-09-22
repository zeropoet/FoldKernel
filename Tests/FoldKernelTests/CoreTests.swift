import Testing
@testable import FoldKernel

@Suite("Permutation validation")
struct PermutationTests {
    @Test func acceptsAscendingSequence() throws {
        let expected = Array(1...16).map(UInt8.init)
        #expect(try Permutation(expected).values == expected)
    }

    @Test func acceptsCanonicalS0() throws {
        let expected: [UInt8] = [
            13, 3, 2, 16, 8, 10, 11, 5,
            12, 6, 7, 9, 1, 15, 14, 4
        ]
        #expect(try Permutation(expected).values == expected)
    }

    @Test func rejectsDuplicates() {
        expectPermutationError(.duplicateValue) {
            try Permutation([1, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
        }
    }

    @Test func rejectsOutOfRange() {
        expectPermutationError(.outOfRange) {
            try Permutation([0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16])
        }
    }

    @Test func rejectsInvalidLength() {
        expectPermutationError(.invalidLength) {
            try Permutation([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
        }
    }

    private func expectPermutationError(
        _ expected: PermutationError,
        operation: () throws -> Permutation
    ) {
        do {
            _ = try operation()
            Issue.record("Expected permutation error: \(expected)")
        } catch {
            #expect(error as? PermutationError == expected)
        }
    }
}

@Suite("D4 symmetry")
struct SymmetryTests {
    @Test func canonicalSquareIsExact() {
        #expect(CanonicalSquare.S0.values == [
            13, 3, 2, 16, 8, 10, 11, 5,
            12, 6, 7, 9, 1, 15, 14, 4
        ])
    }

    @Test func rotationsReturnToIdentity() {
        let base = CanonicalSquare.S0

        var rotate90 = base
        for _ in 0..<4 { rotate90 = SymmetryTransform.rotate90.apply(to: rotate90) }
        #expect(rotate90 == base)

        var rotate180 = base
        for _ in 0..<2 { rotate180 = SymmetryTransform.rotate180.apply(to: rotate180) }
        #expect(rotate180 == base)

        var rotate270 = base
        for _ in 0..<4 { rotate270 = SymmetryTransform.rotate270.apply(to: rotate270) }
        #expect(rotate270 == base)
    }

    @Test func reflectionsReturnToIdentity() {
        let base = CanonicalSquare.S0
        let reflections: [SymmetryTransform] = [
            .reflectHorizontal, .reflectVertical,
            .reflectMainDiagonal, .reflectAntiDiagonal
        ]

        for reflection in reflections {
            let twice = reflection.apply(to: reflection.apply(to: base))
            #expect(twice == base)
        }
    }

    @Test func orbitContainsExactlyEightMembers() {
        let orbit = SymmetryTransform.allCases.map { $0.apply(to: CanonicalSquare.S0) }
        #expect(Set(orbit).count == 8)
    }
}

@Suite("Adjacency graph")
struct AdjacencyTests {
    @Test func allValuesArePresentWithExpectedDegrees() {
        let graph = AdjacencyGraph(from: CanonicalSquare.S0)
        let degrees = graph.adjacency.values.map(\.count)

        #expect(graph.adjacency.count == 16)
        #expect(degrees.filter { $0 == 3 }.count == 4)
        #expect(degrees.filter { $0 == 5 }.count == 8)
        #expect(degrees.filter { $0 == 8 }.count == 4)
    }

    @Test func knownNeighborsAreExact() {
        let graph = AdjacencyGraph(from: CanonicalSquare.S0)
        #expect(graph.adjacency[10] == Set<UInt8>([13, 3, 2, 8, 11, 12, 6, 7]))
        #expect(graph.adjacency[13] == Set<UInt8>([3, 8, 10]))
    }

    @Test func canonicalOrbitPreservesAdjacency() {
        let expected = AdjacencyGraph(from: CanonicalSquare.S0).adjacency
        for transform in SymmetryTransform.allCases {
            let transformed = transform.apply(to: CanonicalSquare.S0)
            #expect(AdjacencyGraph(from: transformed).adjacency == expected)
        }
    }
}

@Suite("Arithmetic invariant")
struct InvariantTests {
    @Test func canonicalS0SatisfiesInvariant() {
        let result = InvariantEvaluator().evaluate(CanonicalSquare.S0)
        #expect(result.isSatisfied)
        #expect(result.deviation == 0)
    }

    @Test func ascendingPermutationDoesNotSatisfyInvariant() throws {
        let ascending = try Permutation(Array(1...16).map(UInt8.init))
        let result = InvariantEvaluator().evaluate(ascending)
        #expect(!result.isSatisfied)
        #expect(result.deviation > 0)
    }

    @Test func singleSwapCreatesDeviation() {
        var values = CanonicalSquare.S0.values
        values.swapAt(0, 1)
        let result = InvariantEvaluator().evaluate(Permutation(validated: values))
        #expect(!result.isSatisfied)
        #expect(result.deviation > 0)
    }

    @Test func evaluationIsDeterministic() {
        let evaluator = InvariantEvaluator()
        let first = evaluator.evaluate(CanonicalSquare.S0)
        let second = evaluator.evaluate(CanonicalSquare.S0)
        #expect(first.isSatisfied == second.isSatisfied)
        #expect(first.deviation == second.deviation)
    }
}

@Suite("Canonical distance")
struct CanonicalDistanceTests {
    private var canonicalSet: Set<Permutation> {
        Set(SymmetryTransform.allCases.map { $0.apply(to: CanonicalSquare.S0) })
    }

    @Test func canonicalOrbitDistanceIsZero() {
        let metric = CanonicalDistance(canonicalSet: canonicalSet)
        for canonical in canonicalSet { #expect(metric.distance(from: canonical) == 0) }
    }

    @Test func ascendingPermutationDistanceIsPositive() throws {
        let ascending = try Permutation(Array(1...16).map(UInt8.init))
        #expect(CanonicalDistance(canonicalSet: canonicalSet).distance(from: ascending) > 0)
    }

    @Test func singleSwapDistanceIsPositive() {
        var values = CanonicalSquare.S0.values
        values.swapAt(0, 1)
        let swapped = Permutation(validated: values)
        #expect(CanonicalDistance(canonicalSet: canonicalSet).distance(from: swapped) > 0)
    }

    @Test func distanceIsDeterministic() {
        let metric = CanonicalDistance(canonicalSet: canonicalSet)
        #expect(metric.distance(from: CanonicalSquare.S0) == metric.distance(from: CanonicalSquare.S0))
    }
}

@Suite("Structural convergence")
struct ConvergenceTests {
    private var canonicalSet: Set<Permutation> {
        Set(SymmetryTransform.allCases.map { $0.apply(to: CanonicalSquare.S0) })
    }

    private func makeEvaluator() -> ConvergenceEvaluator {
        let set = canonicalSet
        return ConvergenceEvaluator(
            canonicalSet: set,
            adjacencyGraph: AdjacencyGraph(from: CanonicalSquare.S0),
            invariantEvaluator: InvariantEvaluator(),
            canonicalDistance: CanonicalDistance(canonicalSet: set)
        )
    }

    @Test func canonicalOrbitSatisfiesAllChecks() {
        let evaluator = makeEvaluator()
        for canonical in canonicalSet {
            let state = evaluator.evaluate(canonical)
            #expect(state.isCanonical)
            #expect(state.sumSatisfied)
            #expect(state.adjacencySatisfied)
        }
    }

    @Test func ascendingPermutationFailsAllChecks() throws {
        let state = makeEvaluator().evaluate(try Permutation(Array(1...16).map(UInt8.init)))
        #expect(!state.isCanonical)
        #expect(!state.sumSatisfied)
        #expect(!state.adjacencySatisfied)
    }

    @Test func swapFailsAllChecks() {
        var values = CanonicalSquare.S0.values
        values.swapAt(0, 1)
        let state = makeEvaluator().evaluate(Permutation(validated: values))
        #expect(!state.isCanonical)
        #expect(!state.sumSatisfied)
        #expect(!state.adjacencySatisfied)
    }

    @Test func evaluationIsDeterministic() {
        let evaluator = makeEvaluator()
        let first = evaluator.evaluate(CanonicalSquare.S0)
        let second = evaluator.evaluate(CanonicalSquare.S0)
        #expect(first.isCanonical == second.isCanonical)
        #expect(first.sumSatisfied == second.sumSatisfied)
        #expect(first.adjacencySatisfied == second.adjacencySatisfied)
    }
}

@Suite("Memory encoding")
struct MemoryEncodingTests {
    @Test func individualEventLengthsAreExact() throws {
        let permutation = try Permutation(Array(1...16).map(UInt8.init))
        #expect(MemoryEncoder().encode([.permutationCommit(permutation)]).count == 17)
        #expect(MemoryEncoder().encode([.lockStateChange(0x07)]).count == 2)
        #expect(MemoryEncoder().encode([.foldTopologyChange(0x01)]).count == 2)
    }

    @Test func combinedSequenceIsByteExactAndDeterministic() throws {
        let permutation = try Permutation(Array(1...16).map(UInt8.init))
        let events: [FoldEvent] = [
            .permutationCommit(permutation),
            .lockStateChange(0x07),
            .foldTopologyChange(0x01)
        ]
        let expected: [UInt8] = [
            0x01, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
            0x02, 0x07, 0x03, 0x01
        ]
        let encoder = MemoryEncoder()
        #expect(encoder.encode(events) == expected)
        #expect(encoder.encode(events) == encoder.encode(events))
    }
}

@Suite("Keccak-256")
struct KeccakTests {
    @Test func standardVectorsAreExact() throws {
        let emptyDigest = try bytes(fromHex: "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470")
        let abcDigest = try bytes(fromHex: "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45")
        #expect(Keccak256().hash([]) == emptyDigest)
        #expect(Keccak256().hash([0x61, 0x62, 0x63]) == abcDigest)
    }

    @Test func rateBoundaryVectorsAreExact() throws {
        let vectors: [(Int, String)] = [
            (135, "cbdfd9dee5faad3818d6b06f95a219fd290b0e1706f6a82e5a595b9ce9faca62"),
            (136, "7ce759f1ab7f9ce437719970c26b0a66ff11fe3e38e17df89cf5d29c7d7f807e"),
            (137, "ac73d4fae68b8453f764007c1a20ce95994187861f0c3227a3a8e99a73a3b1db"),
            (272, "fdf2ec49e749960d3c8521a0219af8d03e30e2b3bf19bd16150ee0eaf133d66e")
        ]
        for (count, digest) in vectors {
            let input = (0..<count).map { UInt8($0 % 256) }
            let expected = try bytes(fromHex: digest)
            #expect(Keccak256().hash(input) == expected)
        }
    }

    @Test func hashingIsDeterministic() {
        let input = Array("FoldKernel".utf8)
        #expect(Keccak256().hash(input) == Keccak256().hash(input))
    }
}

@Suite("Convergence hash")
struct HashEngineTests {
    @Test func knownSignatureIsExact() throws {
        let expected = try bytes(fromHex: "0c6ed2168c4bbc60aabd871964c43d515d2ffab1b9329d76dc741a72ac8cfe77")
        #expect(HashEngine().convergenceHash(memorySignature: [0x01, 0x02, 0x03]) == expected)
    }

    @Test func completeEventHistoryIsExact() throws {
        let permutation = try Permutation(Array(1...16).map(UInt8.init))
        let signature = MemoryEncoder().encode([
            .permutationCommit(permutation),
            .lockStateChange(0x07),
            .foldTopologyChange(0x01)
        ])
        let expectedSignature: [UInt8] = [
            0x01, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
            0x02, 0x07, 0x03, 0x01
        ]
        let expectedHash = try bytes(fromHex: "4c27728c1a912f94a424aa7951573a1f40e047433b0774b442e1f4c65e53af5e")
        #expect(signature == expectedSignature)
        #expect(HashEngine().convergenceHash(memorySignature: signature) == expectedHash)
    }
}

private func bytes(fromHex hex: String) throws -> [UInt8] {
    guard hex.count.isMultiple(of: 2) else { throw HexError.invalid(hex) }
    var result: [UInt8] = []
    var index = hex.startIndex
    while index < hex.endIndex {
        let next = hex.index(index, offsetBy: 2)
        guard let byte = UInt8(hex[index..<next], radix: 16) else { throw HexError.invalid(hex) }
        result.append(byte)
        index = next
    }
    return result
}

private enum HexError: Error {
    case invalid(String)
}

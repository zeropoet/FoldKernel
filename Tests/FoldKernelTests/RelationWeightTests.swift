import Foundation
import Testing
@testable import FoldKernel

@Suite("Relation Weight 1.1")
struct RelationWeightTests {
    private let a = String(repeating: "a", count: 64)
    private let b = String(repeating: "b", count: 64)
    private let c = String(repeating: "c", count: 64)
    private let e1 = String(repeating: "1", count: 64)
    private let e2 = String(repeating: "2", count: 64)
    private let e3 = String(repeating: "3", count: 64)

    @Test("Independent evidence becomes weight and node mass")
    func derivesWeights() throws {
        let map = try FoldKernelRelationContract.derive([
            observation(a, b, "conditions", e1),
            observation(a, b, "conditions", e2),
            observation(b, c, "informs", e3),
        ])

        #expect(map.contractVersion == "FoldKernel-Relation-1.1.0")
        #expect(map.coreProtocolVersion == "FoldKernel-1.0.0")
        #expect(map.uniqueObservationCount == 3)
        #expect(map.relationMapID == "f8cb0a2521540338b83b3b85fa068a1dad2af6725f2b75a342c25c8781440763")
        #expect(map.relations == [
            FoldRelationWeight(sourceIdentity: a, targetIdentity: b, kind: "conditions", weight: 2),
            FoldRelationWeight(sourceIdentity: b, targetIdentity: c, kind: "informs", weight: 1),
        ])
        #expect(map.nodes == [
            FoldNodeMass(identity: a, mass: 2),
            FoldNodeMass(identity: b, mass: 3),
            FoldNodeMass(identity: c, mass: 1),
        ])
    }

    @Test("Order and duplicate delivery do not change identity")
    func canonicalizesInput() throws {
        let first = observation(a, b, "conditions", e1)
        let second = observation(a, b, "conditions", e2)
        let left = try FoldKernelRelationContract.derive([first, second, first])
        let right = try FoldKernelRelationContract.derive([second, first])
        #expect(left == right)
        #expect(left.uniqueObservationCount == 2)
        #expect(left.relations.first?.weight == 2)
    }

    @Test("Direction and kind remain distinct")
    func preservesSemantics() throws {
        let map = try FoldKernelRelationContract.derive([
            observation(a, b, "conditions", e1),
            observation(b, a, "conditions", e2),
            observation(a, b, "informs", e3),
        ])
        #expect(map.relations.count == 3)
    }

    @Test("Invalid and self relations are rejected")
    func rejectsInvalidInput() throws {
        #expect(throws: FoldRelationError.selfRelation) {
            try FoldRelationObservation(sourceIdentity: a, targetIdentity: a, kind: "informs", evidenceDigest: e1)
        }
        #expect(throws: FoldRelationError.invalidKind) {
            try FoldRelationObservation(sourceIdentity: a, targetIdentity: b, kind: "Writes Through", evidenceDigest: e1)
        }
        #expect(throws: FoldRelationError.emptyObservations) {
            try FoldKernelRelationContract.derive([])
        }
    }

    @Test("Count boundary is checked without trapping")
    func countBoundary() throws {
        #expect(try FoldKernelRelationContract.checkedObservationCount(Int(UInt32.max)) == UInt32.max)
        #expect(throws: FoldRelationError.observationCountOverflow) {
            try FoldKernelRelationContract.checkedObservationCount(Int(UInt32.max) + 1)
        }
    }

    @Test("Validation rejects noncanonical bytes")
    func rejectsNoncanonicalBytes() throws {
        for kind in ["informs\n", "", "Informs", "é", String(repeating: "a", count: 65)] {
            #expect(throws: FoldRelationError.invalidKind) {
                try FoldRelationObservation(sourceIdentity: a, targetIdentity: b, kind: kind, evidenceDigest: e1)
            }
        }
        for digest in [a + "\n", String(repeating: "A", count: 64), "abc"] {
            #expect(throws: FoldRelationError.invalidSourceIdentity) {
                try FoldRelationObservation(sourceIdentity: digest, targetIdentity: b, kind: "informs", evidenceDigest: e1)
            }
            #expect(throws: FoldRelationError.invalidTargetIdentity) {
                try FoldRelationObservation(sourceIdentity: a, targetIdentity: digest, kind: "informs", evidenceDigest: e1)
            }
            #expect(throws: FoldRelationError.invalidEvidenceDigest) {
                try FoldRelationObservation(sourceIdentity: a, targetIdentity: b, kind: "informs", evidenceDigest: digest)
            }
        }
    }

    @Test("Normative vector fixes bytes and serialized output")
    func normativeVector() throws {
        struct Observation: Decodable {
            let sourceIdentity: String
            let targetIdentity: String
            let kind: String
            let evidenceDigest: String
        }
        struct Vector: Decodable {
            let observations: [Observation]
            let canonicalBytesHex: String
            let expected: FoldRelationMap
        }
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Resources/relation-weight-vectors.json")
        let vector = try JSONDecoder().decode(Vector.self, from: Data(contentsOf: url))
        let observations = try vector.observations.map {
            try FoldRelationObservation(sourceIdentity: $0.sourceIdentity, targetIdentity: $0.targetIdentity,
                                        kind: $0.kind, evidenceDigest: $0.evidenceDigest)
        }
        let bytes = try FoldKernelRelationContract.encode(observations)
        #expect(bytes.map { String(format: "%02x", $0) }.joined() == vector.canonicalBytesHex)
        let map = try FoldKernelRelationContract.derive(observations)
        #expect(map == vector.expected)
        #expect(try JSONDecoder().decode(FoldRelationMap.self, from: JSONEncoder().encode(map)) == map)
        #expect(try FoldKernelRelationContract.derive(Array(observations.reversed())) == map)
    }

    private func observation(
        _ source: String,
        _ target: String,
        _ kind: String,
        _ evidence: String
    ) -> FoldRelationObservation {
        try! FoldRelationObservation(
            sourceIdentity: source,
            targetIdentity: target,
            kind: kind,
            evidenceDigest: evidence
        )
    }
}

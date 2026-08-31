import Testing
@testable import FoldKernel

@Suite("Transformation Receipt 1.0")
struct TransformationReceiptTests {
    private let source = String(repeating: "a", count: 64)
    private let output = String(repeating: "b", count: 64)
    private let evidence = String(repeating: "c", count: 64)

    @Test("A preserved transformation is deterministic")
    func deterministicTransformation() throws {
        let first = try transformed()
        let second = try transformed()
        #expect(first == second)
        #expect(first.receiptID == "7250d094516f04cc053b397d23c85de8aa200f2912f93a766a1471cfad13ad9d")
        #expect(first.sourcePreserved)
        #expect(first.destructive == false)
        #expect(first.monetary == false)
        try FoldKernelTransformationReceiptContract.verify(first)
    }

    @Test("A derived transformation requires a distinct output")
    func transformationRequiresOutput() throws {
        #expect(throws: FoldKernelTransformationReceiptError.self) {
            try FoldKernelTransformationReceiptContract.issue(
                sourceSystem: "foldforge", eventID: "missing-output",
                sourceArtifactDigest: source, sourceKind: "source_audio",
                transitionKind: .transformed, evidenceDigest: evidence,
                occurredOn: "2026-08-31"
            )
        }
        #expect(throws: FoldKernelTransformationReceiptError.self) {
            try FoldKernelTransformationReceiptContract.issue(
                sourceSystem: "foldforge", eventID: "same-output",
                sourceArtifactDigest: source, sourceKind: "source_audio",
                transitionKind: .transformed, outputArtifactDigest: source,
                outputKind: "sonic_master", evidenceDigest: evidence,
                occurredOn: "2026-08-31"
            )
        }
    }

    @Test("Retirement preserves source identity without inventing an output")
    func preservationWithoutOutput() throws {
        let receipt = try FoldKernelTransformationReceiptContract.issue(
            sourceSystem: "root-logos", eventID: "archive-revision-0001",
            sourceArtifactDigest: source, sourceKind: "published_fragment",
            transitionKind: .retired, evidenceDigest: evidence,
            occurredOn: "2026-08-31"
        )
        #expect(receipt.outputArtifactDigest == nil)
        #expect(receipt.outputKind == nil)
        #expect(receipt.sourcePreserved)
    }

    private func transformed() throws -> FoldKernelTransformationReceipt {
        try FoldKernelTransformationReceiptContract.issue(
            sourceSystem: "foldforge", eventID: "sonic-master-0001",
            sourceArtifactDigest: source, sourceKind: "source_audio",
            transitionKind: .transformed, outputArtifactDigest: output,
            outputKind: "sonic_master", evidenceDigest: evidence,
            occurredOn: "2026-08-31"
        )
    }
}

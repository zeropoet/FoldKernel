import Testing
@testable import FoldKernel

@Suite("Value Receipt 1.0")
struct ValueReceiptTests {
    private let artifact = String(repeating: "a", count: 64)
    private let valuation = String(repeating: "b", count: 64)
    private let settlement = String(repeating: "c", count: 64)

    @Test("A value lifecycle is deterministic and externally evidenced")
    func completeLifecycle() throws {
        let unrealized = try issue()
        #expect(unrealized == (try issue()))
        #expect(unrealized.receiptID == "965c00a3ba26862000540f67fb61b8c8eded05d4141bd7f7b9824c478d641fef")
        #expect(unrealized.monetaryCounterpartCents == nil)

        let evidenced = try FoldKernelValueReceiptContract.advance(unrealized, to: .evidenced)
        let realized = try FoldKernelValueReceiptContract.advance(
            evidenced, to: .realized, valuationBasis: .settledReceipt,
            monetaryCounterpartCents: 4_200, valuationEvidenceDigest: valuation
        )
        let settled = try FoldKernelValueReceiptContract.advance(
            realized, to: .settled, settlementEvidenceDigest: settlement
        )

        #expect(Set([unrealized.receiptID, evidenced.receiptID, realized.receiptID, settled.receiptID]).count == 4)
        #expect(settled.priorReceiptID == realized.receiptID)
        #expect(settled.monetaryCounterpartCents == 4_200)
        try FoldKernelValueReceiptContract.verifyTransition(from: realized, to: settled)
    }

    @Test("Internal evidence cannot invent a monetary counterpart")
    func evidenceCannotCarryMoney() throws {
        let evidenced = try FoldKernelValueReceiptContract.advance(try issue(), to: .evidenced)
        #expect(throws: FoldKernelValueReceiptError.self) {
            try FoldKernelValueReceiptContract.advance(evidenced, to: .realized)
        }
    }

    @Test("The lifecycle cannot skip a state")
    func cannotSkipState() throws {
        #expect(throws: FoldKernelValueReceiptError.self) {
            try FoldKernelValueReceiptContract.advance(try issue(), to: .realized)
        }
    }

    @Test("Settlement cannot alter realized value")
    func settlementCannotRevalue() throws {
        let evidenced = try FoldKernelValueReceiptContract.advance(try issue(), to: .evidenced)
        let realized = try FoldKernelValueReceiptContract.advance(
            evidenced, to: .realized, valuationBasis: .verifiedCostAvoidance,
            monetaryCounterpartCents: 2_500, valuationEvidenceDigest: valuation
        )
        #expect(throws: FoldKernelValueReceiptError.self) {
            try FoldKernelValueReceiptContract.advance(
                realized, to: .settled, monetaryCounterpartCents: 2_501,
                settlementEvidenceDigest: settlement
            )
        }
    }

    private func issue() throws -> FoldKernelValueReceipt {
        try FoldKernelValueReceiptContract.issue(
            sourceSystem: "foldforge", eventID: "sonic-master-0001",
            artifactDigest: artifact, outputKind: "sonic_master",
            periodStart: "2026-08-31", periodEnd: "2026-08-31"
        )
    }
}

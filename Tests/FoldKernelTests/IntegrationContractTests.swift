import Foundation
import Testing
@testable import FoldKernel

@Suite("Integration contract")
struct IntegrationContractTests {
    @Test("A bounded declaration produces a commit-specific receipt")
    func boundedDeclarationProducesReceipt() throws {
        let declaration = try declarationData()
        let receipt = try FoldKernelIntegrationContract.createReceipt(
            declarationData: declaration,
            sourceCommit: String(repeating: "a", count: 40),
            verifiedAt: "2026-08-31T12:00:00Z"
        )

        #expect(receipt.consumer.name == "Example Consumer")
        #expect(receipt.sourceCommit == String(repeating: "a", count: 40))
        #expect(receipt.declarationDigest.count == 64)
        #expect(receipt.checksPassed == 15)
        #expect(receipt.valid)
    }

    @Test("Telos cannot gain write authority")
    func rejectsExpandedTelosAuthority() throws {
        var value = try #require(JSONSerialization.jsonObject(with: declarationData()) as? [String: Any])
        var authority = try #require(value["authority"] as? [String: Any])
        authority["telosMay"] = ["alter_foldkernel_output"]
        value["authority"] = authority

        #expect(throws: FoldKernelIntegrationError.self) {
            try FoldKernelIntegrationContract.verifyDeclaration(
                data: JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
            )
        }
    }

    private func declarationData() throws -> Data {
        let report = try FoldKernelIntegrationContract.conformanceReport()
        let value: [String: Any] = [
            "contractVersion": "FoldKernel-Integration-1.0.0",
            "consumer": [
                "name": "Example Consumer",
                "repository": "https://github.com/example/consumer",
                "publicManifestURL": "https://example.com/foldkernel-integration.json",
            ],
            "foldKernel": [
                "protocolVersion": "FoldKernel-1.0.0",
                "packageRequirement": ["kind": "exact", "version": "1.0.3"],
                "conformanceVectors": ["algorithm": "keccak-256", "digest": report.vectorDigest],
            ],
            "authority": [
                "applicationOwns": ["application_history", "artifact_interpretation", "event_meaning"],
                "foldKernelOwns": ["canonical_encoding", "conformance_contract", "convergence_identity"],
                "telosMay": ["observe_declared_versions", "report_drift", "verify_public_conformance"],
                "telosMustNot": ["absorb_application_authority", "alter_foldkernel_output", "write_application_history"],
            ],
            "eventMeanings": [[
                "event": "permutation_commit",
                "owner": "Example Consumer",
                "meaning": "Application-owned structural state",
            ]],
        ]
        return try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    }
}

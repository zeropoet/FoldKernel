import Testing
@testable import FoldKernel

@Suite("Language-neutral conformance vectors")
struct ConformanceVectorTests {
    @Test("Committed vectors reproduce byte-for-byte")
    func committedVectorsReproduceExactly() throws {
        let report = try FoldKernelIntegrationContract.conformanceReport()

        #expect(report.protocolVersion == "FoldKernel-1.0.0")
        #expect(report.vectorAlgorithm == "keccak-256")
        #expect(report.vectorDigest.count == 64)
        #expect(report.checksPassed == 15)
        #expect(report.valid)
    }
}

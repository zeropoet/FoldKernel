import XCTest
@testable import FoldKernel

final class HashEngineTests: XCTestCase {
    func testKnownMemorySignatureHash() {
        let engine = HashEngine()
        let signature: [UInt8] = [0x01, 0x02, 0x03]

        let expected = bytes(fromHex: "0c6ed2168c4bbc60aabd871964c43d515d2ffab1b9329d76dc741a72ac8cfe77")
        XCTAssertEqual(engine.convergenceHash(memorySignature: signature), expected)
    }

    func testCompleteEventHistoryGoldenVector() throws {
        let permutation = try Permutation(Array(1...16).map(UInt8.init))
        let events: [FoldEvent] = [
            .permutationCommit(permutation),
            .lockStateChange(0x07),
            .foldTopologyChange(0x01)
        ]

        let signature = MemoryEncoder().encode(events)
        let expectedSignature: [UInt8] = [
            0x01,
            1, 2, 3, 4, 5, 6, 7, 8,
            9, 10, 11, 12, 13, 14, 15, 16,
            0x02, 0x07,
            0x03, 0x01
        ]
        let expectedHash = bytes(fromHex: "4c27728c1a912f94a424aa7951573a1f40e047433b0774b442e1f4c65e53af5e")

        XCTAssertEqual(signature, expectedSignature)
        XCTAssertEqual(HashEngine().convergenceHash(memorySignature: signature), expectedHash)
    }

    private func bytes(fromHex hex: String) -> [UInt8] {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(hex.count / 2)

        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            let pair = String(hex[index..<next])
            bytes.append(UInt8(pair, radix: 16)!)
            index = next
        }

        return bytes
    }
}

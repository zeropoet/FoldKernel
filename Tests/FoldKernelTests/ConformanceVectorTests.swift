import Foundation
import Testing
@testable import FoldKernel

@Suite("Language-neutral conformance vectors")
struct ConformanceVectorTests {
    @Test("Committed vectors reproduce byte-for-byte")
    func committedVectorsReproduceExactly() throws {
        let vectors = try loadVectors()

        #expect(vectors.protocolVersion == "FoldKernel-1.0.0")
        #expect(CanonicalSquare.S0.values == vectors.canonicalSquare)

        let transforms: [(String, SymmetryTransform)] = [
            ("identity", .identity),
            ("rotate90", .rotate90),
            ("rotate180", .rotate180),
            ("rotate270", .rotate270),
            ("reflectHorizontal", .reflectHorizontal),
            ("reflectVertical", .reflectVertical),
            ("reflectMainDiagonal", .reflectMainDiagonal),
            ("reflectAntiDiagonal", .reflectAntiDiagonal)
        ]

        for (name, transform) in transforms {
            let expected = try #require(vectors.symmetryOrbit[name])
            #expect(transform.apply(to: CanonicalSquare.S0).values == expected)
        }

        for vector in vectors.keccak256 {
            let input = try bytes(fromHex: vector.inputHex)
            let expected = try bytes(fromHex: vector.digestHex)
            #expect(Keccak256().hash(input) == expected, Comment(rawValue: vector.name))
        }

        for vector in vectors.memoryHistories {
            let signature = try bytes(fromHex: vector.memorySignatureHex)
            let expected = try bytes(fromHex: vector.convergenceHashHex)
            #expect(
                HashEngine().convergenceHash(memorySignature: signature) == expected,
                Comment(rawValue: vector.name)
            )
        }
    }

    private func loadVectors() throws -> ConformanceVectors {
        let url = try #require(
            Bundle.module.url(forResource: "conformance-vectors", withExtension: "json")
        )
        return try JSONDecoder().decode(ConformanceVectors.self, from: Data(contentsOf: url))
    }

    private func bytes(fromHex hex: String) throws -> [UInt8] {
        guard hex.count.isMultiple(of: 2) else {
            throw VectorError.invalidHex(hex)
        }

        var result: [UInt8] = []
        result.reserveCapacity(hex.count / 2)
        var index = hex.startIndex

        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else {
                throw VectorError.invalidHex(hex)
            }
            result.append(byte)
            index = next
        }

        return result
    }
}

private struct ConformanceVectors: Decodable {
    let protocolVersion: String
    let canonicalSquare: [UInt8]
    let symmetryOrbit: [String: [UInt8]]
    let keccak256: [KeccakVector]
    let memoryHistories: [MemoryHistoryVector]
}

private struct KeccakVector: Decodable {
    let name: String
    let inputHex: String
    let digestHex: String
}

private struct MemoryHistoryVector: Decodable {
    let name: String
    let memorySignatureHex: String
    let convergenceHashHex: String
}

private enum VectorError: Error {
    case invalidHex(String)
}

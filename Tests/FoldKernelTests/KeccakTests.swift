import XCTest
@testable import FoldKernel

final class KeccakTests: XCTestCase {
    func testEmptyInputVector() {
        let keccak = Keccak256()
        let expected = bytes(fromHex: "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470")

        XCTAssertEqual(keccak.hash([]), expected)
    }

    func testABCTestVector() {
        let keccak = Keccak256()
        let expected = bytes(fromHex: "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45")

        XCTAssertEqual(keccak.hash([0x61, 0x62, 0x63]), expected)
    }

    func testRateBoundaryVectors() {
        let keccak = Keccak256()
        let vectors: [(count: Int, digest: String)] = [
            (135, "cbdfd9dee5faad3818d6b06f95a219fd290b0e1706f6a82e5a595b9ce9faca62"),
            (136, "7ce759f1ab7f9ce437719970c26b0a66ff11fe3e38e17df89cf5d29c7d7f807e"),
            (137, "ac73d4fae68b8453f764007c1a20ce95994187861f0c3227a3a8e99a73a3b1db"),
            (272, "fdf2ec49e749960d3c8521a0219af8d03e30e2b3bf19bd16150ee0eaf133d66e")
        ]

        for vector in vectors {
            let input = (0..<vector.count).map { UInt8($0 % 256) }
            XCTAssertEqual(keccak.hash(input), bytes(fromHex: vector.digest), "Input length: \(vector.count)")
        }
    }

    func testDeterminism() {
        let keccak = Keccak256()
        let input = Array("FoldKernel".utf8)

        XCTAssertEqual(keccak.hash(input), keccak.hash(input))
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

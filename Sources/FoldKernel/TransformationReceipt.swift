import Foundation

/// A deterministic witness that records an artifact's consequential change without
/// destroying, transferring, pricing, or replacing the source artifact.
/// This additive contract does not participate in FoldKernel-1.0.0 convergence hashes.
public enum FoldKernelTransformationReceiptContract {
    public static let version = "FoldKernel-Transformation-Receipt-1.0.0"
    public static let digestAlgorithm = "keccak-256"

    public static func issue(
        sourceSystem: String,
        eventID: String,
        sourceArtifactDigest: String,
        sourceKind: String,
        transitionKind: FoldKernelTransformationKind,
        outputArtifactDigest: String? = nil,
        outputKind: String? = nil,
        evidenceDigest: String,
        occurredOn: String
    ) throws -> FoldKernelTransformationReceipt {
        var receipt = FoldKernelTransformationReceipt(
            contractVersion: version,
            digestAlgorithm: digestAlgorithm,
            receiptID: "",
            sourceSystem: sourceSystem,
            eventID: eventID,
            sourceArtifactDigest: sourceArtifactDigest,
            sourceKind: sourceKind,
            transitionKind: transitionKind,
            outputArtifactDigest: outputArtifactDigest,
            outputKind: outputKind,
            evidenceDigest: evidenceDigest,
            occurredOn: occurredOn,
            sourcePreserved: true,
            destructive: false,
            transferable: false,
            purchasable: false,
            appreciating: false,
            monetary: false,
            personalData: false
        )
        try validate(receipt)
        receipt.receiptID = digest(receipt)
        return receipt
    }

    public static func verify(_ receipt: FoldKernelTransformationReceipt) throws {
        try validate(receipt)
        guard receipt.receiptID == digest(receipt) else {
            throw FoldKernelTransformationReceiptError.invalidReceipt("receipt digest does not match its canonical payload")
        }
    }

    private static func validate(_ receipt: FoldKernelTransformationReceipt) throws {
        guard receipt.contractVersion == version else {
            throw FoldKernelTransformationReceiptError.invalidReceipt("contract version")
        }
        guard receipt.digestAlgorithm == digestAlgorithm else {
            throw FoldKernelTransformationReceiptError.invalidReceipt("digest algorithm")
        }
        try requireMatch(receipt.sourceSystem, "^[a-z0-9][a-z0-9._-]{0,119}$", "source system")
        try requireMatch(receipt.eventID, "^[A-Za-z0-9][A-Za-z0-9._:-]{0,119}$", "event ID")
        try requireDigest(receipt.sourceArtifactDigest, "source artifact digest")
        try requireMatch(receipt.sourceKind, "^[a-z0-9][a-z0-9._-]{0,79}$", "source kind")
        try requireDigest(receipt.evidenceDigest, "evidence digest")
        try requireDate(receipt.occurredOn, "occurrence date")

        guard (receipt.outputArtifactDigest == nil) == (receipt.outputKind == nil) else {
            throw FoldKernelTransformationReceiptError.invalidReceipt("output identity must be complete or absent")
        }
        if let outputDigest = receipt.outputArtifactDigest, let outputKind = receipt.outputKind {
            try requireDigest(outputDigest, "output artifact digest")
            try requireMatch(outputKind, "^[a-z0-9][a-z0-9._-]{0,79}$", "output kind")
            guard outputDigest != receipt.sourceArtifactDigest else {
                throw FoldKernelTransformationReceiptError.invalidReceipt("output artifact must differ from its source")
            }
        }
        if receipt.transitionKind.requiresOutput,
           receipt.outputArtifactDigest == nil {
            throw FoldKernelTransformationReceiptError.invalidReceipt("transition requires a derived output")
        }

        guard receipt.sourcePreserved,
              receipt.destructive == false,
              receipt.transferable == false,
              receipt.purchasable == false,
              receipt.appreciating == false,
              receipt.monetary == false,
              receipt.personalData == false else {
            throw FoldKernelTransformationReceiptError.invalidReceipt("version 1.0 preservation and safety flags are invalid")
        }
    }

    private static func digest(_ receipt: FoldKernelTransformationReceipt) -> String {
        var bytes: [UInt8] = []
        append(version, to: &bytes)
        append(receipt.digestAlgorithm, to: &bytes)
        append(receipt.sourceSystem, to: &bytes)
        append(receipt.eventID, to: &bytes)
        appendDigest(receipt.sourceArtifactDigest, to: &bytes)
        append(receipt.sourceKind, to: &bytes)
        append(receipt.transitionKind.rawValue, to: &bytes)
        appendOptionalDigest(receipt.outputArtifactDigest, to: &bytes)
        appendOptional(receipt.outputKind, to: &bytes)
        appendDigest(receipt.evidenceDigest, to: &bytes)
        append(receipt.occurredOn, to: &bytes)
        bytes += [1, 0, 0, 0, 0, 0, 0]
        return Keccak256().hash(bytes).map { String(format: "%02x", $0) }.joined()
    }

    private static func append(_ value: String, to bytes: inout [UInt8]) {
        let encoded = Array(value.utf8)
        let count = UInt32(encoded.count)
        bytes += [UInt8(count >> 24), UInt8(count >> 16), UInt8(count >> 8), UInt8(count)]
        bytes += encoded
    }

    private static func appendDigest(_ value: String, to bytes: inout [UInt8]) {
        var index = value.startIndex
        while index < value.endIndex {
            let next = value.index(index, offsetBy: 2)
            bytes.append(UInt8(value[index..<next], radix: 16)!)
            index = next
        }
    }

    private static func appendOptional(_ value: String?, to bytes: inout [UInt8]) {
        guard let value else { bytes.append(0); return }
        bytes.append(1)
        append(value, to: &bytes)
    }

    private static func appendOptionalDigest(_ value: String?, to bytes: inout [UInt8]) {
        guard let value else { bytes.append(0); return }
        bytes.append(1)
        appendDigest(value, to: &bytes)
    }

    private static func requireDigest(_ value: String, _ label: String) throws {
        try requireMatch(value, "^[0-9a-f]{64}$", label)
    }

    private static func requireMatch(_ value: String, _ pattern: String, _ label: String) throws {
        guard value.range(of: pattern, options: .regularExpression) != nil else {
            throw FoldKernelTransformationReceiptError.invalidReceipt(label)
        }
    }

    private static func requireDate(_ value: String, _ label: String) throws {
        try requireMatch(value, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", label)
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              (1...12).contains(parts[1]),
              (1...daysInMonth(parts[1], year: parts[0])).contains(parts[2]) else {
            throw FoldKernelTransformationReceiptError.invalidReceipt(label)
        }
    }

    private static func daysInMonth(_ month: Int, year: Int) -> Int {
        if month == 2 { return (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) ? 29 : 28 }
        return [4, 6, 9, 11].contains(month) ? 30 : 31
    }
}

public enum FoldKernelTransformationKind: String, Codable, CaseIterable, Sendable {
    case transformed
    case fulfilled
    case consumed
    case superseded
    case retired

    fileprivate var requiresOutput: Bool {
        self == .transformed || self == .fulfilled
    }
}

public struct FoldKernelTransformationReceipt: Codable, Equatable, Sendable {
    public let contractVersion: String
    public let digestAlgorithm: String
    public fileprivate(set) var receiptID: String
    public let sourceSystem: String
    public let eventID: String
    public let sourceArtifactDigest: String
    public let sourceKind: String
    public let transitionKind: FoldKernelTransformationKind
    public let outputArtifactDigest: String?
    public let outputKind: String?
    public let evidenceDigest: String
    public let occurredOn: String
    public let sourcePreserved: Bool
    public let destructive: Bool
    public let transferable: Bool
    public let purchasable: Bool
    public let appreciating: Bool
    public let monetary: Bool
    public let personalData: Bool
}

public enum FoldKernelTransformationReceiptError: Error, LocalizedError {
    case invalidReceipt(String)

    public var errorDescription: String? {
        switch self {
        case .invalidReceipt(let reason): return "Invalid FoldKernel transformation receipt: \(reason)"
        }
    }
}

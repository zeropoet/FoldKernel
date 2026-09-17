import Foundation

/// A deterministic, non-transferable receipt for useful work moving toward settlement.
/// This contract is additive and does not participate in FoldKernel-1.0.0 convergence hashes.
public enum FoldKernelValueReceiptContract {
    public static let version = "FoldKernel-Value-Receipt-1.0.0"
    public static let digestAlgorithm = "keccak-256"

    public static func issue(
        sourceSystem: String,
        eventID: String,
        artifactDigest: String,
        outputKind: String,
        periodStart: String,
        periodEnd: String,
        state: FoldKernelValueState = .unrealized
    ) throws -> FoldKernelValueReceipt {
        guard state == .unrealized || state == .evidenced else {
            throw FoldKernelValueReceiptError.invalidReceipt("an initial receipt must be unrealized or evidenced")
        }
        return try makeReceipt(
            sourceSystem: sourceSystem,
            eventID: eventID,
            artifactDigest: artifactDigest,
            outputKind: outputKind,
            periodStart: periodStart,
            periodEnd: periodEnd,
            state: state,
            valuationBasis: .none,
            currency: nil,
            monetaryCounterpartCents: nil,
            valuationEvidenceDigest: nil,
            settlementEvidenceDigest: nil,
            priorReceiptID: nil
        )
    }

    public static func advance(
        _ previous: FoldKernelValueReceipt,
        to state: FoldKernelValueState,
        valuationBasis: FoldKernelValueBasis? = nil,
        monetaryCounterpartCents: UInt64? = nil,
        valuationEvidenceDigest: String? = nil,
        settlementEvidenceDigest: String? = nil
    ) throws -> FoldKernelValueReceipt {
        try verify(previous)
        guard previous.state.next == state else {
            throw FoldKernelValueReceiptError.invalidTransition("\(previous.state.rawValue) cannot advance to \(state.rawValue)")
        }

        let carriesMoney = state == .realized || state == .settled
        let basis = valuationBasis ?? (carriesMoney ? previous.valuationBasis : .none)
        let amount = monetaryCounterpartCents ?? (carriesMoney ? previous.monetaryCounterpartCents : nil)
        let valueEvidence = valuationEvidenceDigest ?? (carriesMoney ? previous.valuationEvidenceDigest : nil)

        let receipt = try makeReceipt(
            sourceSystem: previous.sourceSystem,
            eventID: previous.eventID,
            artifactDigest: previous.artifactDigest,
            outputKind: previous.outputKind,
            periodStart: previous.periodStart,
            periodEnd: previous.periodEnd,
            state: state,
            valuationBasis: basis,
            currency: carriesMoney ? "USD" : nil,
            monetaryCounterpartCents: amount,
            valuationEvidenceDigest: valueEvidence,
            settlementEvidenceDigest: settlementEvidenceDigest,
            priorReceiptID: previous.receiptID
        )
        try verifyTransition(from: previous, to: receipt)
        return receipt
    }

    public static func verify(_ receipt: FoldKernelValueReceipt) throws {
        try validateIdentity(receipt)
        try validateState(receipt)
        guard receipt.receiptID == digest(receipt) else {
            throw FoldKernelValueReceiptError.invalidReceipt("receipt digest does not match its canonical payload")
        }
    }

    public static func verifyTransition(
        from previous: FoldKernelValueReceipt,
        to current: FoldKernelValueReceipt
    ) throws {
        try verify(previous)
        try verify(current)
        guard previous.state.next == current.state else {
            throw FoldKernelValueReceiptError.invalidTransition("states are not consecutive")
        }
        guard current.priorReceiptID == previous.receiptID else {
            throw FoldKernelValueReceiptError.invalidTransition("prior receipt does not match")
        }
        guard previous.sourceSystem == current.sourceSystem,
              previous.eventID == current.eventID,
              previous.artifactDigest == current.artifactDigest,
              previous.outputKind == current.outputKind,
              previous.periodStart == current.periodStart,
              previous.periodEnd == current.periodEnd else {
            throw FoldKernelValueReceiptError.invalidTransition("work identity changed")
        }
        if current.state == .settled {
            guard previous.valuationBasis == current.valuationBasis,
                  previous.currency == current.currency,
                  previous.monetaryCounterpartCents == current.monetaryCounterpartCents,
                  previous.valuationEvidenceDigest == current.valuationEvidenceDigest else {
                throw FoldKernelValueReceiptError.invalidTransition("realized value changed during settlement")
            }
        }
    }

    private static func makeReceipt(
        sourceSystem: String,
        eventID: String,
        artifactDigest: String,
        outputKind: String,
        periodStart: String,
        periodEnd: String,
        state: FoldKernelValueState,
        valuationBasis: FoldKernelValueBasis,
        currency: String?,
        monetaryCounterpartCents: UInt64?,
        valuationEvidenceDigest: String?,
        settlementEvidenceDigest: String?,
        priorReceiptID: String?
    ) throws -> FoldKernelValueReceipt {
        var receipt = FoldKernelValueReceipt(
            contractVersion: version,
            digestAlgorithm: digestAlgorithm,
            receiptID: "",
            sourceSystem: sourceSystem,
            eventID: eventID,
            artifactDigest: artifactDigest,
            outputKind: outputKind,
            periodStart: periodStart,
            periodEnd: periodEnd,
            state: state,
            valuationBasis: valuationBasis,
            currency: currency,
            monetaryCounterpartCents: monetaryCounterpartCents,
            valuationEvidenceDigest: valuationEvidenceDigest,
            settlementEvidenceDigest: settlementEvidenceDigest,
            priorReceiptID: priorReceiptID,
            transferable: false,
            purchasable: false,
            appreciating: false,
            personalData: false
        )
        try validateIdentity(receipt)
        try validateState(receipt)
        receipt.receiptID = digest(receipt)
        return receipt
    }

    private static func validateIdentity(_ receipt: FoldKernelValueReceipt) throws {
        guard receipt.contractVersion == version else {
            throw FoldKernelValueReceiptError.invalidReceipt("contract version")
        }
        guard receipt.digestAlgorithm == digestAlgorithm else {
            throw FoldKernelValueReceiptError.invalidReceipt("digest algorithm")
        }
        try requireMatch(receipt.sourceSystem, "^[a-z0-9][a-z0-9._-]{0,119}$", "source system")
        try requireMatch(receipt.eventID, "^[A-Za-z0-9][A-Za-z0-9._:-]{0,119}$", "event ID")
        try requireDigest(receipt.artifactDigest, "artifact digest")
        try requireMatch(receipt.outputKind, "^[a-z0-9][a-z0-9._-]{0,79}$", "output kind")
        try requireDate(receipt.periodStart, "period start")
        try requireDate(receipt.periodEnd, "period end")
        guard receipt.periodStart <= receipt.periodEnd else {
            throw FoldKernelValueReceiptError.invalidReceipt("period end precedes period start")
        }
        if let prior = receipt.priorReceiptID { try requireDigest(prior, "prior receipt ID") }
        guard receipt.transferable == false,
              receipt.purchasable == false,
              receipt.appreciating == false,
              receipt.personalData == false else {
            throw FoldKernelValueReceiptError.invalidReceipt("version 1.0 safety flags must remain false")
        }
    }

    private static func validateState(_ receipt: FoldKernelValueReceipt) throws {
        switch receipt.state {
        case .unrealized, .evidenced:
            guard receipt.valuationBasis == .none,
                  receipt.currency == nil,
                  receipt.monetaryCounterpartCents == nil,
                  receipt.valuationEvidenceDigest == nil,
                  receipt.settlementEvidenceDigest == nil else {
                throw FoldKernelValueReceiptError.invalidReceipt("unsettled evidence may not carry money")
            }
        case .realized:
            try requireMonetaryEvidence(receipt)
            guard receipt.settlementEvidenceDigest == nil else {
                throw FoldKernelValueReceiptError.invalidReceipt("realized value may not claim settlement")
            }
        case .settled:
            try requireMonetaryEvidence(receipt)
            guard let digest = receipt.settlementEvidenceDigest else {
                throw FoldKernelValueReceiptError.invalidReceipt("settled value requires settlement evidence")
            }
            try requireDigest(digest, "settlement evidence digest")
        }
        if receipt.state == .unrealized && receipt.priorReceiptID != nil {
            throw FoldKernelValueReceiptError.invalidReceipt("unrealized value must begin a receipt chain")
        }
        if receipt.state == .realized || receipt.state == .settled {
            guard receipt.priorReceiptID != nil else {
                throw FoldKernelValueReceiptError.invalidReceipt("monetary state requires a prior receipt")
            }
        }
    }

    private static func requireMonetaryEvidence(_ receipt: FoldKernelValueReceipt) throws {
        guard receipt.valuationBasis != .none else {
            throw FoldKernelValueReceiptError.invalidReceipt("monetary value requires a valuation basis")
        }
        guard receipt.currency == "USD" else {
            throw FoldKernelValueReceiptError.invalidReceipt("version 1.0 monetary counterparts use USD")
        }
        guard let amount = receipt.monetaryCounterpartCents, amount > 0 else {
            throw FoldKernelValueReceiptError.invalidReceipt("monetary counterpart must be positive integer cents")
        }
        guard let evidence = receipt.valuationEvidenceDigest else {
            throw FoldKernelValueReceiptError.invalidReceipt("monetary value requires external evidence")
        }
        try requireDigest(evidence, "valuation evidence digest")
    }

    private static func digest(_ receipt: FoldKernelValueReceipt) -> String {
        var bytes: [UInt8] = []
        append(version, to: &bytes)
        append(receipt.digestAlgorithm, to: &bytes)
        append(receipt.sourceSystem, to: &bytes)
        append(receipt.eventID, to: &bytes)
        appendDigest(receipt.artifactDigest, to: &bytes)
        append(receipt.outputKind, to: &bytes)
        append(receipt.periodStart, to: &bytes)
        append(receipt.periodEnd, to: &bytes)
        append(receipt.state.rawValue, to: &bytes)
        append(receipt.valuationBasis.rawValue, to: &bytes)
        appendOptional(receipt.currency, to: &bytes)
        appendOptional(receipt.monetaryCounterpartCents, to: &bytes)
        appendOptionalDigest(receipt.valuationEvidenceDigest, to: &bytes)
        appendOptionalDigest(receipt.settlementEvidenceDigest, to: &bytes)
        appendOptionalDigest(receipt.priorReceiptID, to: &bytes)
        bytes += [0, 0, 0, 0]
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

    private static func appendOptional(_ value: UInt64?, to bytes: inout [UInt8]) {
        guard let value else { bytes.append(0); return }
        bytes.append(1)
        for shift in stride(from: 56, through: 0, by: -8) {
            bytes.append(UInt8((value >> UInt64(shift)) & 0xff))
        }
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
            throw FoldKernelValueReceiptError.invalidReceipt(label)
        }
    }

    private static func requireDate(_ value: String, _ label: String) throws {
        try requireMatch(value, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$", label)
        let parts = value.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3,
              (1...12).contains(parts[1]),
              (1...daysInMonth(parts[1], year: parts[0])).contains(parts[2]) else {
            throw FoldKernelValueReceiptError.invalidReceipt(label)
        }
    }

    private static func daysInMonth(_ month: Int, year: Int) -> Int {
        if month == 2 { return (year % 400 == 0 || (year % 4 == 0 && year % 100 != 0)) ? 29 : 28 }
        return [4, 6, 9, 11].contains(month) ? 30 : 31
    }
}

public enum FoldKernelValueState: String, Codable, CaseIterable, Sendable {
    case unrealized
    case evidenced
    case realized
    case settled

    fileprivate var next: FoldKernelValueState? {
        switch self {
        case .unrealized: return .evidenced
        case .evidenced: return .realized
        case .realized: return .settled
        case .settled: return nil
        }
    }
}

public enum FoldKernelValueBasis: String, Codable, CaseIterable, Sendable {
    case none
    case settledReceipt = "settled_receipt"
    case verifiedCostAvoidance = "verified_cost_avoidance"
    case redemptionObligation = "redemption_obligation"
}

public struct FoldKernelValueReceipt: Codable, Equatable, Sendable {
    public let contractVersion: String
    public let digestAlgorithm: String
    public fileprivate(set) var receiptID: String
    public let sourceSystem: String
    public let eventID: String
    public let artifactDigest: String
    public let outputKind: String
    public let periodStart: String
    public let periodEnd: String
    public let state: FoldKernelValueState
    public let valuationBasis: FoldKernelValueBasis
    public let currency: String?
    public let monetaryCounterpartCents: UInt64?
    public let valuationEvidenceDigest: String?
    public let settlementEvidenceDigest: String?
    public let priorReceiptID: String?
    public let transferable: Bool
    public let purchasable: Bool
    public let appreciating: Bool
    public let personalData: Bool
}

public enum FoldKernelValueReceiptError: Error, LocalizedError {
    case invalidReceipt(String)
    case invalidTransition(String)

    public var errorDescription: String? {
        switch self {
        case .invalidReceipt(let reason): return "Invalid FoldKernel value receipt: \(reason)"
        case .invalidTransition(let reason): return "Invalid FoldKernel value transition: \(reason)"
        }
    }
}

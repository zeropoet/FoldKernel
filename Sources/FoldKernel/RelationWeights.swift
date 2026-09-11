import Foundation

/// FoldKernel 1.1's additive, deterministic relation-weight contract.
///
/// FoldKernel counts independently evidenced observations. Applications own
/// admission, semantics, and interpretation; the kernel owns canonicalization,
/// deduplication, weighting, and identity.
public enum FoldKernelRelationContract {
    public static let version = "FoldKernel-Relation-1.1.0"
    public static let coreProtocolVersion = "FoldKernel-1.0.0"
    public static let digestAlgorithm = "keccak-256"

    public static func derive(
        _ observations: [FoldRelationObservation]
    ) throws -> FoldRelationMap {
        guard !observations.isEmpty else {
            throw FoldRelationError.emptyObservations
        }

        let canonical = Array(Set(observations)).sorted()
        _ = try checkedObservationCount(canonical.count)
        var grouped: [FoldRelationKey: UInt32] = [:]
        var nodeMass: [String: UInt64] = [:]

        for observation in canonical {
            let key = FoldRelationKey(
                sourceIdentity: observation.sourceIdentity,
                targetIdentity: observation.targetIdentity,
                kind: observation.kind
            )
            grouped[key, default: 0] += 1
            nodeMass[observation.sourceIdentity, default: 0] += 1
            nodeMass[observation.targetIdentity, default: 0] += 1
        }

        let relations = grouped.keys.sorted().map { key in
            FoldRelationWeight(
                sourceIdentity: key.sourceIdentity,
                targetIdentity: key.targetIdentity,
                kind: key.kind,
                weight: grouped[key]!
            )
        }
        let nodes = nodeMass.keys.sorted().map {
            FoldNodeMass(identity: $0, mass: nodeMass[$0]!)
        }
        let bytes = try encode(canonical)

        return FoldRelationMap(
            contractVersion: version,
            coreProtocolVersion: coreProtocolVersion,
            digestAlgorithm: digestAlgorithm,
            relationMapID: hex(Keccak256().hash(bytes)),
            uniqueObservationCount: UInt32(canonical.count),
            relations: relations,
            nodes: nodes
        )
    }

    /// Canonical bytes: version, unique observation count, then observations
    /// sorted by source, target, kind, and evidence. Digests are raw 32 bytes;
    /// kind is a two-byte big-endian length followed by UTF-8.
    public static func encode(
        _ observations: [FoldRelationObservation]
    ) throws -> [UInt8] {
        let canonical = Array(Set(observations)).sorted()
        _ = try checkedObservationCount(canonical.count)
        var bytes = Array(version.utf8)
        append(UInt32(canonical.count), to: &bytes)
        for observation in canonical {
            bytes.append(contentsOf: bytesFromHex(observation.sourceIdentity))
            bytes.append(contentsOf: bytesFromHex(observation.targetIdentity))
            let kind = Array(observation.kind.utf8)
            append(UInt16(kind.count), to: &bytes)
            bytes.append(contentsOf: kind)
            bytes.append(contentsOf: bytesFromHex(observation.evidenceDigest))
        }
        return bytes
    }

    // Internal so the UInt32 boundary can be tested without allocating billions of observations.
    static func checkedObservationCount(_ count: Int) throws -> UInt32 {
        guard let value = UInt32(exactly: count) else {
            throw FoldRelationError.observationCountOverflow
        }
        return value
    }

    private static func append(_ value: UInt16, to bytes: inout [UInt8]) {
        bytes.append(UInt8((value >> 8) & 0xff))
        bytes.append(UInt8(value & 0xff))
    }

    private static func append(_ value: UInt32, to bytes: inout [UInt8]) {
        bytes.append(UInt8((value >> 24) & 0xff))
        bytes.append(UInt8((value >> 16) & 0xff))
        bytes.append(UInt8((value >> 8) & 0xff))
        bytes.append(UInt8(value & 0xff))
    }

    private static func bytesFromHex(_ value: String) -> [UInt8] {
        var result: [UInt8] = []
        var index = value.startIndex
        while index < value.endIndex {
            let next = value.index(index, offsetBy: 2)
            result.append(UInt8(value[index..<next], radix: 16)!)
            index = next
        }
        return result
    }

    private static func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
}

public struct FoldRelationObservation: Hashable, Sendable, Comparable {
    public let sourceIdentity: String
    public let targetIdentity: String
    public let kind: String
    public let evidenceDigest: String

    public init(
        sourceIdentity: String,
        targetIdentity: String,
        kind: String,
        evidenceDigest: String
    ) throws {
        guard Self.isDigest(sourceIdentity) else {
            throw FoldRelationError.invalidSourceIdentity
        }
        guard Self.isDigest(targetIdentity) else {
            throw FoldRelationError.invalidTargetIdentity
        }
        guard sourceIdentity != targetIdentity else {
            throw FoldRelationError.selfRelation
        }
        let kindBytes = Array(kind.utf8)
        guard (1...64).contains(kindBytes.count),
              kindBytes.first.map({ (97...122).contains($0) }) == true,
              kindBytes.allSatisfy({ (97...122).contains($0) || (48...57).contains($0) || [45, 46, 95].contains($0) }) else {
            throw FoldRelationError.invalidKind
        }
        guard Self.isDigest(evidenceDigest) else {
            throw FoldRelationError.invalidEvidenceDigest
        }
        self.sourceIdentity = sourceIdentity
        self.targetIdentity = targetIdentity
        self.kind = kind
        self.evidenceDigest = evidenceDigest
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.sourceIdentity != rhs.sourceIdentity { return lhs.sourceIdentity < rhs.sourceIdentity }
        if lhs.targetIdentity != rhs.targetIdentity { return lhs.targetIdentity < rhs.targetIdentity }
        if lhs.kind != rhs.kind { return lhs.kind < rhs.kind }
        return lhs.evidenceDigest < rhs.evidenceDigest
    }

    private static func isDigest(_ value: String) -> Bool {
        value.utf8.count == 64 && value.utf8.allSatisfy { (48...57).contains($0) || (97...102).contains($0) }
    }
}

public struct FoldRelationWeight: Codable, Equatable, Sendable {
    public let sourceIdentity: String
    public let targetIdentity: String
    public let kind: String
    public let weight: UInt32
}

public struct FoldNodeMass: Codable, Equatable, Sendable {
    public let identity: String
    public let mass: UInt64
}

public struct FoldRelationMap: Codable, Equatable, Sendable {
    public let contractVersion: String
    public let coreProtocolVersion: String
    public let digestAlgorithm: String
    public let relationMapID: String
    public let uniqueObservationCount: UInt32
    public let relations: [FoldRelationWeight]
    public let nodes: [FoldNodeMass]
}

public enum FoldRelationError: Error, Equatable, LocalizedError {
    case observationCountOverflow
    case emptyObservations
    case invalidSourceIdentity
    case invalidTargetIdentity
    case selfRelation
    case invalidKind
    case invalidEvidenceDigest

    public var errorDescription: String? {
        switch self {
        case .observationCountOverflow: return "The unique observation count exceeds UInt32.max."
        case .emptyObservations: return "A relation map requires at least one observation."
        case .invalidSourceIdentity: return "The source identity must be 32 lowercase hexadecimal bytes."
        case .invalidTargetIdentity: return "The target identity must be 32 lowercase hexadecimal bytes."
        case .selfRelation: return "A relation must connect two distinct identities."
        case .invalidKind: return "The relation kind is not canonical."
        case .invalidEvidenceDigest: return "The evidence digest must be 32 lowercase hexadecimal bytes."
        }
    }
}

private struct FoldRelationKey: Hashable, Comparable {
    let sourceIdentity: String
    let targetIdentity: String
    let kind: String

    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.sourceIdentity != rhs.sourceIdentity { return lhs.sourceIdentity < rhs.sourceIdentity }
        if lhs.targetIdentity != rhs.targetIdentity { return lhs.targetIdentity < rhs.targetIdentity }
        return lhs.kind < rhs.kind
    }
}

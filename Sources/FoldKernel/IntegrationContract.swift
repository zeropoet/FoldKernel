import Foundation

public enum FoldKernelIntegrationContract {
    public static let version = "FoldKernel-Integration-1.0.0"
    public static let protocolVersion = "FoldKernel-1.0.0"
    public static let vectorAlgorithm = "keccak-256"

    public static let applicationAuthority = Set([
        "application_history",
        "artifact_interpretation",
        "event_meaning",
    ])
    public static let kernelAuthority = Set([
        "canonical_encoding",
        "conformance_contract",
        "convergence_identity",
    ])
    public static let telosObservationAuthority = Set([
        "observe_declared_versions",
        "report_drift",
        "verify_public_conformance",
    ])
    public static let telosProhibitions = Set([
        "absorb_application_authority",
        "alter_foldkernel_output",
        "write_application_history",
    ])

    public static func conformanceReport() throws -> FoldKernelConformanceReport {
        let data = try conformanceVectorData()
        let vectors = try JSONDecoder().decode(ConformanceVectors.self, from: data)
        var checks = 0

        try require(vectors.protocolVersion == protocolVersion, "protocol version")
        checks += 1
        try require(CanonicalSquare.S0.values == vectors.canonicalSquare, "canonical square")
        checks += 1

        let transforms: [(String, SymmetryTransform)] = [
            ("identity", .identity),
            ("rotate90", .rotate90),
            ("rotate180", .rotate180),
            ("rotate270", .rotate270),
            ("reflectHorizontal", .reflectHorizontal),
            ("reflectVertical", .reflectVertical),
            ("reflectMainDiagonal", .reflectMainDiagonal),
            ("reflectAntiDiagonal", .reflectAntiDiagonal),
        ]
        for (name, transform) in transforms {
            guard let expected = vectors.symmetryOrbit[name] else {
                throw FoldKernelIntegrationError.invalidVectors("missing symmetry \(name)")
            }
            try require(transform.apply(to: CanonicalSquare.S0).values == expected, "symmetry \(name)")
            checks += 1
        }

        for vector in vectors.keccak256 {
            try require(
                Keccak256().hash(try bytes(fromHex: vector.inputHex)) == bytes(fromHex: vector.digestHex),
                "keccak vector \(vector.name)"
            )
            checks += 1
        }

        for vector in vectors.memoryHistories {
            try require(
                HashEngine().convergenceHash(memorySignature: try bytes(fromHex: vector.memorySignatureHex))
                    == bytes(fromHex: vector.convergenceHashHex),
                "memory history \(vector.name)"
            )
            checks += 1
        }

        return FoldKernelConformanceReport(
            protocolVersion: protocolVersion,
            vectorAlgorithm: vectorAlgorithm,
            vectorDigest: hex(Keccak256().hash(Array(data))),
            checksPassed: checks,
            valid: true
        )
    }

    public static func verifyDeclaration(data: Data) throws -> FoldKernelIntegrationDeclaration {
        let declaration: FoldKernelIntegrationDeclaration
        do {
            declaration = try JSONDecoder().decode(FoldKernelIntegrationDeclaration.self, from: data)
        } catch {
            throw FoldKernelIntegrationError.invalidDeclaration("JSON does not match the integration contract")
        }

        try require(declaration.contractVersion == version, "integration contract version")
        try require(!declaration.consumer.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "consumer name")
        try require(validPublicURL(declaration.consumer.repository), "consumer repository URL")
        try require(validPublicURL(declaration.consumer.publicManifestURL), "public manifest URL")
        try require(declaration.foldKernel.protocolVersion == protocolVersion, "declared protocol version")
        try require(declaration.foldKernel.packageRequirement.kind == "exact", "exact package requirement")
        try require(validSemanticVersion(declaration.foldKernel.packageRequirement.version), "package version")

        let report = try conformanceReport()
        try require(declaration.foldKernel.conformanceVectors.algorithm == vectorAlgorithm, "vector algorithm")
        try require(declaration.foldKernel.conformanceVectors.digest == report.vectorDigest, "vector digest")
        try require(Set(declaration.authority.applicationOwns) == applicationAuthority, "application authority")
        try require(Set(declaration.authority.foldKernelOwns) == kernelAuthority, "FoldKernel authority")
        try require(Set(declaration.authority.telosMay) == telosObservationAuthority, "Telos observation authority")
        try require(Set(declaration.authority.telosMustNot) == telosProhibitions, "Telos prohibitions")
        try require(!declaration.eventMeanings.isEmpty, "event meanings")

        var names = Set<String>()
        let supportedEvents = Set(["permutation_commit", "lock_state_change", "fold_topology_change"])
        for event in declaration.eventMeanings {
            try require(supportedEvents.contains(event.event), "event name \(event.event)")
            try require(names.insert(event.event).inserted, "unique event name \(event.event)")
            try require(event.owner == declaration.consumer.name, "event owner \(event.event)")
            try require(!event.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "event meaning \(event.event)")
        }

        return declaration
    }

    public static func createReceipt(
        declarationData: Data,
        sourceCommit: String,
        verifiedAt: String
    ) throws -> FoldKernelIntegrationReceipt {
        let declaration = try verifyDeclaration(data: declarationData)
        try require(sourceCommit.range(of: "^[0-9a-f]{40}$", options: .regularExpression) != nil, "source commit")
        try require(ISO8601DateFormatter().date(from: verifiedAt) != nil, "verification timestamp")
        let report = try conformanceReport()
        return FoldKernelIntegrationReceipt(
            contractVersion: version,
            consumer: declaration.consumer,
            sourceCommit: sourceCommit,
            verifiedAt: verifiedAt,
            declarationDigest: hex(Keccak256().hash(Array(declarationData))),
            foldKernel: declaration.foldKernel,
            checksPassed: report.checksPassed,
            valid: report.valid
        )
    }

    private static func conformanceVectorData() throws -> Data {
        guard let url = Bundle.module.url(forResource: "conformance-vectors", withExtension: "json") else {
            throw FoldKernelIntegrationError.invalidVectors("resource is missing")
        }
        return try Data(contentsOf: url)
    }

    private static func validPublicURL(_ value: String) -> Bool {
        guard let components = URLComponents(string: value),
              components.scheme == "https",
              components.host != nil,
              components.user == nil,
              components.password == nil,
              components.fragment == nil else { return false }
        return true
    }

    private static func validSemanticVersion(_ value: String) -> Bool {
        value.range(of: "^[0-9]+\\.[0-9]+\\.[0-9]+$", options: .regularExpression) != nil
    }

    private static func require(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
        guard try condition() else {
            throw FoldKernelIntegrationError.invalidDeclaration(label)
        }
    }

    private static func bytes(fromHex value: String) throws -> [UInt8] {
        guard value.count.isMultiple(of: 2) else {
            throw FoldKernelIntegrationError.invalidVectors("invalid hex")
        }
        var bytes: [UInt8] = []
        var index = value.startIndex
        while index < value.endIndex {
            let next = value.index(index, offsetBy: 2)
            guard let byte = UInt8(value[index..<next], radix: 16) else {
                throw FoldKernelIntegrationError.invalidVectors("invalid hex")
            }
            bytes.append(byte)
            index = next
        }
        return bytes
    }

    private static func hex(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }
}

public struct FoldKernelConformanceReport: Codable, Equatable, Sendable {
    public let protocolVersion: String
    public let vectorAlgorithm: String
    public let vectorDigest: String
    public let checksPassed: Int
    public let valid: Bool
}

public struct FoldKernelIntegrationDeclaration: Codable, Equatable, Sendable {
    public let contractVersion: String
    public let consumer: FoldKernelConsumer
    public let foldKernel: FoldKernelDeclaration
    public let authority: FoldKernelAuthorityDeclaration
    public let eventMeanings: [FoldKernelEventMeaning]
}

public struct FoldKernelConsumer: Codable, Equatable, Sendable {
    public let name: String
    public let repository: String
    public let publicManifestURL: String
}

public struct FoldKernelDeclaration: Codable, Equatable, Sendable {
    public let protocolVersion: String
    public let packageRequirement: FoldKernelPackageRequirement
    public let conformanceVectors: FoldKernelVectorDeclaration
}

public struct FoldKernelPackageRequirement: Codable, Equatable, Sendable {
    public let kind: String
    public let version: String
}

public struct FoldKernelVectorDeclaration: Codable, Equatable, Sendable {
    public let algorithm: String
    public let digest: String
}

public struct FoldKernelAuthorityDeclaration: Codable, Equatable, Sendable {
    public let applicationOwns: [String]
    public let foldKernelOwns: [String]
    public let telosMay: [String]
    public let telosMustNot: [String]
}

public struct FoldKernelEventMeaning: Codable, Equatable, Sendable {
    public let event: String
    public let owner: String
    public let meaning: String
}

public struct FoldKernelIntegrationReceipt: Codable, Equatable, Sendable {
    public let contractVersion: String
    public let consumer: FoldKernelConsumer
    public let sourceCommit: String
    public let verifiedAt: String
    public let declarationDigest: String
    public let foldKernel: FoldKernelDeclaration
    public let checksPassed: Int
    public let valid: Bool
}

public enum FoldKernelIntegrationError: Error, LocalizedError {
    case invalidDeclaration(String)
    case invalidVectors(String)

    public var errorDescription: String? {
        switch self {
        case .invalidDeclaration(let reason):
            return "Invalid FoldKernel integration declaration: \(reason)"
        case .invalidVectors(let reason):
            return "Invalid FoldKernel conformance vectors: \(reason)"
        }
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

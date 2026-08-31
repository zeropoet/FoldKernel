import FoldKernel

private let defaultValues = CanonicalSquare.S0.values
private let arguments = CommandLine.arguments.dropFirst()

private let values: [UInt8]
private let lockState: UInt8
private let topology: UInt8

if arguments.isEmpty {
    values = defaultValues
    lockState = 7
    topology = 1
} else {
    guard arguments.count == 3 else {
        fatalError("Usage: fold-kernel-example <16 comma-separated values> <lock-state byte> <topology byte>")
    }

    let supplied = Array(arguments)
    let parsedValues = supplied[0].split(separator: ",").compactMap { UInt8($0) }
    guard parsedValues.count == 16,
          let parsedLockState = UInt8(supplied[1]),
          let parsedTopology = UInt8(supplied[2]) else {
        fatalError("Inputs must contain 16 byte values followed by two decimal bytes")
    }

    values = parsedValues
    lockState = parsedLockState
    topology = parsedTopology
}

do {
    let permutation = try Permutation(values)
    let events: [FoldEvent] = [
        .permutationCommit(permutation),
        .lockStateChange(lockState),
        .foldTopologyChange(topology)
    ]
    let signature = MemoryEncoder().encode(events)
    let digest = HashEngine().convergenceHash(memorySignature: signature)
    let canonicalSet = Set(
        SymmetryTransform.allCases.map { $0.apply(to: CanonicalSquare.S0) }
    )
    let state = ConvergenceEvaluator(
        canonicalSet: canonicalSet,
        adjacencyGraph: AdjacencyGraph(from: CanonicalSquare.S0),
        invariantEvaluator: InvariantEvaluator(),
        canonicalDistance: CanonicalDistance(canonicalSet: canonicalSet)
    ).evaluate(permutation)

    print("protocol=FoldKernel-1.0.0")
    print("permutation=\(values.map(String.init).joined(separator: ","))")
    print("memory_signature=\(hex(signature))")
    print("convergence_hash=\(hex(digest))")
    print("canonical=\(state.isCanonical)")
    print("sum_invariant=\(state.sumSatisfied)")
    print("adjacency_invariant=\(state.adjacencySatisfied)")
} catch {
    fatalError("Invalid FoldKernel permutation: \(error)")
}

private func hex(_ bytes: [UInt8]) -> String {
    let digits = Array("0123456789abcdef".utf8)
    var encoded: [UInt8] = []
    encoded.reserveCapacity(bytes.count * 2)

    for byte in bytes {
        encoded.append(digits[Int(byte >> 4)])
        encoded.append(digits[Int(byte & 0x0f)])
    }

    return String(decoding: encoded, as: UTF8.self)
}

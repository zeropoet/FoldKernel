# FoldKernel Developer Preview

This preview is the smallest path from a structured interaction state to a
reproducible FoldKernel identity. It is deliberately local, inspectable, and
free of accounts, network calls, timestamps, and managed services.

## Requirements

- Swift 5.9 or newer
- macOS 10.15 or a supported Swift Linux environment

## Run the reference example

Clone the repository and run:

```bash
swift run fold-kernel-example
```

The default example commits canonical square `S0`, lock-state byte `7`, and
topology byte `1`. It prints the encoded memory bytes, convergence hash, and
three independent structural checks.

```text
protocol=FoldKernel-1.0.0
permutation=13,3,2,16,8,10,11,5,12,6,7,9,1,15,14,4
memory_signature=010d030210080a0b050c060709010f0e0402070301
convergence_hash=dae462e1178f1670b8f7c207a78581316d51249dd5dff632df87a73cc0c029b8
canonical=true
sum_invariant=true
adjacency_invariant=true
```

Supply another valid permutation and state as decimal bytes:

```bash
swift run fold-kernel-example \
  1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16 7 1
```

## Add the package to a Swift project

Pin a reviewed release rather than following `main`:

```swift
dependencies: [
    .package(
        url: "https://github.com/zeropoet/FoldKernel.git",
        exact: "1.0.5"
    )
]
```

Then depend on the `FoldKernel` product and encode an event history:

```swift
import FoldKernel

let permutation = try Permutation([
    13, 3, 2, 16,
    8, 10, 11, 5,
    12, 6, 7, 9,
    1, 15, 14, 4
])

let memory = MemoryEncoder().encode([
    .permutationCommit(permutation),
    .lockStateChange(7),
    .foldTopologyChange(1)
])
let identity = HashEngine().convergenceHash(memorySignature: memory)
```

The application owns the meaning of its lock-state and topology bytes. The
kernel owns only their canonical encoding and the resulting identity.

## Verify compatibility

Before another language or runtime claims compatibility, it must reproduce
every value in
[`conformance-vectors.json`](Tests/FoldKernelTests/Resources/conformance-vectors.json).
The governing byte contract is [`PROTOCOL.md`](PROTOCOL.md).

```bash
swift test
Scripts/verify-developer-preview.sh
```

An implementation must not call itself FoldKernel-compatible merely because it
produces a 256-bit hash. It must preserve validation order, canonical data,
transform mappings, adjacency, invariants, memory bytes, version prefix, and
Keccak construction.

## Declare an integration

Copy the shape defined by
[`Integration/foldkernel-integration.schema.json`](Integration/foldkernel-integration.schema.json)
into the consuming repository as `foldkernel-integration.json`. Declare the
exact package version, the public manifest URL, application-owned meanings for
each Fold event used, and the fixed authority sets.

CI should then create evidence for the exact consumer commit it tested:

```bash
swift run fold-kernel-integration verify foldkernel-integration.json \
  --source-commit "$GITHUB_SHA" \
  --verified-at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --output "$RUNNER_TEMP/foldkernel-integration-receipt.json"
```

The declaration is stable; the receipt is commit-specific. Keeping these two
layers separate avoids a self-referential manifest that changes the commit it
claims to verify. Receipts may be retained as CI artifacts or by a separately
bounded evidence service.

## Current boundary

This repository is an MIT-licensed protocol and reference implementation. It
does not currently provide hosting, signing, identity custody, a registry,
certification, service-level guarantees, private instruments, or a Telos
account. Those are separate future product surfaces described in
[`PRODUCT.md`](PRODUCT.md).

# FoldKernel

FoldKernel is a deterministic protocol engine for generating verifiable coherence artifacts.

## Telos relation

Telos is the connected system's final caretaker and keeper. It may witness
FoldKernel's public identity and relations, but it cannot alter the protocol or
replace its deterministic authority. Those bounded relations can shape Telos's
evolving **Living System**. Telos is growing toward a machine-native visual,
sonic, and open-orientation language capable of noticing drift and preserving
relation, without claiming consciousness, revelation, personhood, or final
authority.

It defines the mathematical and cryptographic rules used by the Fold coherence instrument to transform structured interaction into reproducible symbolic artifacts.

The kernel contains no user interface, rendering system, or application logic.
It exists purely as protocol infrastructure.

FoldKernel guarantees that identical interaction histories always produce identical artifacts.
This determinism allows Fold artifacts to be independently reproduced, verified, and interpreted across different implementations.

The protocol implements the following deterministic pipeline:

interaction
→ permutation events
→ memory signature
→ convergence hash

From this pipeline, higher-level systems can derive symbolic representations such as sigils or registry artifacts without altering the underlying protocol.

FoldKernel is intentionally minimal and stable.
Exploration layers, visualizations, and interaction vessels are built on top of the kernel rather than inside it.

The Swift package is the reference implementation, not the sole definition of
the protocol. The normative byte-level contract is documented in
[`PROTOCOL.md`](PROTOCOL.md), and machine-readable compatibility fixtures live
in [`Tests/FoldKernelTests/Resources/conformance-vectors.json`](Tests/FoldKernelTests/Resources/conformance-vectors.json).
Any future implementation must reproduce those vectors byte-for-byte before it
can claim FoldKernel compatibility.

## Build with FoldKernel

Start with the [developer preview](DEVELOPER.md). A runnable example accepts a
permutation, lock-state byte, and topology byte, then emits the exact memory
signature, convergence hash, and structural state:

```bash
swift run fold-kernel-example
```

The [product boundary](PRODUCT.md) distinguishes the open protocol that exists
today from managed runtime, certification, instrument, and Telos services that
remain future-facing. No paid service is implied by this repository release.

## Integration contract

Applications can publish a stable, public declaration of their FoldKernel
version, event meanings, conformance-vector digest, and authority boundary.
The Swift verifier runs all fifteen canonical checks before it emits a
commit-specific receipt:

```bash
swift run fold-kernel-integration conformance
swift run fold-kernel-integration verify foldkernel-integration.json \
  --source-commit "$GIT_COMMIT" \
  --verified-at "2026-08-31T12:00:00Z" \
  --output foldkernel-integration-receipt.json
```

The declaration schema is
[`Integration/foldkernel-integration.schema.json`](Integration/foldkernel-integration.schema.json).
The application owns event meaning and history, FoldKernel owns canonical
encoding and convergence identity, and Telos may only observe public versions,
verify the declared public contract, and report drift.

---

## Components

FoldKernel provides:

• permutation validation
• canonical square definition
• D4 symmetry orbit
• adjacency graph derivation
• arithmetic invariant evaluation
• canonical distance metric
• structural convergence detection
• stateless memory encoding
• keccak-256 hash derivation

---

## Deterministic Guarantees

For any identical sequence of events:

• the memory signature will be identical  
• the convergence hash will be identical  
• artifacts are reproducible across machines  

FoldKernel contains no randomness, timestamps, or external runtime
dependencies. Its CI pins a Swift 6.1.2 toolchain to run the modern Swift
Testing conformance suite while the package manifest remains compatible with
Swift Package Manager 5.9 consumers.

---

## Version

Current protocol version:

FoldKernel-1.0.0

The protocol version is embedded directly into artifact hashes.

Future revisions will increment this identifier.

Package releases may receive patch-level infrastructure updates without
changing the embedded protocol identifier. Such releases must not alter any
canonical output.

---

## Architecture

FoldKernel is designed to be used by higher-level systems:

FoldKernel → protocol  
Instrument → interaction vessel  
SigilEngine → artifact interpretation

This repository contains only the protocol layer.

---

## Identity

The FoldKernel mark is a load-bearing plan: an outer protocol boundary folds
inward around a protected canonical kernel. Its four equal paths express the
symmetry, deterministic transformation, and structural convergence implemented
by the protocol.

The canonical mark and production variants are maintained in
[`Assets/Brand`](Assets/Brand/README.md).

---

## License

MIT License

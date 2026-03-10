# FoldKernel

FoldKernel is the deterministic protocol engine for the Fold coherence instrument.

It defines the mathematical and cryptographic rules used to generate
verifiable Fold artifacts.

FoldKernel intentionally contains no UI, rendering, or interaction logic.
It exists purely as protocol infrastructure.

---

## Core Pipeline

interaction
→ permutation events
→ memory signature
→ convergence hash

FoldKernel implements the deterministic components required for this pipeline.

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

FoldKernel contains no randomness, timestamps, or external dependencies.

---

## Version

Current protocol version:

FoldKernel-1.0.0

The protocol version is embedded directly into artifact hashes.

Future revisions will increment this identifier.

---

## Architecture

FoldKernel is designed to be used by higher-level systems:

FoldKernel → protocol  
Instrument → interaction vessel  
SigilEngine → artifact interpretation

This repository contains only the protocol layer.

---

## License

MIT License

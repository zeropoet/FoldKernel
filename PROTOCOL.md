# FoldKernel 1.0.0 Protocol

This document is the language-neutral contract for FoldKernel protocol version
`FoldKernel-1.0.0`. The Swift package is its reference implementation. A port is
compatible only when it reproduces the committed conformance vectors exactly.

All byte values are unsigned octets. Arrays preserve their stated order. No
text normalization, timestamps, randomness, platform values, or implicit
delimiters participate in an output.

## Permutation

A permutation is exactly 16 bytes containing every integer from `1` through
`16` exactly once. Validation is performed in this order:

1. A length other than 16 is `invalidLength`.
2. A value outside `1...16` is `outOfRange`.
3. A repeated value is `duplicateValue`.
4. An otherwise incomplete set is `missingValues`.

The canonical square `S0`, in row-major order, is:

```text
13  3  2 16
 8 10 11  5
12  6  7  9
 1 15 14  4
```

## Symmetry orbit

The canonical set is the eight-element D4 orbit of `S0`: identity; rotations
of 90, 180, and 270 degrees clockwise; reflection across the horizontal axis;
reflection across the vertical axis; reflection across the main diagonal; and
reflection across the anti-diagonal.

For every transform, output position `i` receives the input value at the fixed
mapping position for that transform. The exact outputs are normative vectors in
`conformance-vectors.json`.

## Adjacency

Treat a permutation as a row-major 4 by 4 grid. Two values are adjacent when
their distinct cells differ by no more than one row and no more than one
column. This is the eight-neighborhood, including diagonals. The graph maps
every value `1...16` to the unordered set of its neighboring values.

## Arithmetic invariant

Compute the sums of four rows, four columns, the main diagonal, and the
anti-diagonal. The target for each of the ten sums is `34`.

```text
deviation = sum(abs(eachSum - 34))
isSatisfied = deviation == 0
```

All arithmetic is exact integer arithmetic.

## Canonical distance and convergence

Distance is the minimum positional Hamming distance between the candidate and
any member of the injected canonical set. Convergence reports:

- `isCanonical`: canonical distance is zero;
- `sumSatisfied`: the arithmetic invariant is satisfied;
- `adjacencySatisfied`: adjacency equals the canonical `S0` graph for every
  value from `1` through `16`.

The three booleans remain distinct; no one result implies or overwrites
another.

## Memory encoding

Events are concatenated in input order without a count, length prefix, padding,
or separator beyond their event tag:

| Event | Encoding |
| --- | --- |
| permutation commit | `0x01` followed by the 16 permutation bytes |
| lock-state change | `0x02` followed by one bitmask byte |
| fold-topology change | `0x03` followed by one topology byte |

An empty event history encodes to an empty byte string.

## Convergence hash

The convergence hash is Keccak-256—not NIST SHA3-256—over the direct
concatenation of these bytes:

```text
UTF-8("FoldKernel-1.0.0") || memorySignature
```

The Keccak sponge uses a rate of 136 bytes, capacity of 64 bytes, Keccak domain
delimiter `0x01`, final padding bit `0x80`, Keccak-f[1600], and a 32-byte digest.
Digest bytes are serialized in sponge output order and conventionally rendered
as lowercase hexadecimal.

## Compatibility law

Changes to documentation, tests, CI, packaging, or additional implementations
may use a package patch release while retaining protocol identifier
`FoldKernel-1.0.0`, provided every conformance vector remains unchanged.

Any change to validation behavior, canonical data, transform mappings,
adjacency, invariants, event bytes, event ordering, version-prefix bytes,
Keccak construction, or digest output requires a new protocol identifier and a
new vector set. Existing vectors must remain available for historical
verification.

The 1.0.0 Swift reference sources retain Swift 5 language semantics when built
with the Swift 6 toolchain. A language-mode migration is a separate compatibility
change and must first prove all vectors unchanged.

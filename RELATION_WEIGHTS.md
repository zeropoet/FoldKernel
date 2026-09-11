# FoldKernel Relation Weight 1.1

`FoldKernel-Relation-1.1.0` is an additive contract for deriving portable,
deterministic weights from independently evidenced relations. It leaves every
FoldKernel 1.0.0 event encoding, memory signature, convergence hash, and
conformance vector unchanged.

## Weighting law

An observation connects two distinct 32-byte artifact identities with:

- a directed, application-defined relation kind; and
- a 32-byte digest of the evidence supporting that observation.

FoldKernel canonicalizes and deduplicates observations. Each unique evidence
digest contributes one unit of weight to its directed relation. A node's mass
is the sum of the weights of all incoming and outgoing relations incident to
it. Duplicate delivery of the same observation cannot inflate either value.

The kernel does not grade importance, infer meaning, or decide what evidence is
admissible. Those remain application authority. A weight measures the amount
of distinct admitted evidence, not truth, quality, monetary value, similarity,
or artistic significance.

## Canonical encoding

Observations are sorted lexicographically by source identity, target identity,
relation kind, and evidence digest. The relation-map identity is Keccak-256 of:

```text
UTF-8("FoldKernel-Relation-1.1.0")
|| uint32be(unique observation count)
|| each canonical observation:
   source digest (32 bytes)
   || target digest (32 bytes)
   || uint16be(kind UTF-8 byte count)
   || kind UTF-8 bytes
   || evidence digest (32 bytes)
```

Relation kinds match `^[a-z][a-z0-9._-]{0,63}$`. Digests are exactly 64
lowercase hexadecimal characters. Self-relations and empty maps are rejected.

## Demonstrated interpretations

Root Logos may use a relation map to condition grammar, geometry, and derived
tone. Root Logos remains the writer and owns the meanings and admission rules.
Sound is a product of that interpretation, not the cause of the writing.

Sovereign Standard may use a relation map to condition its Sigil Engine and
connect a material vessel with its source, sequence, ingredients, records, and
continuations. Sovereign Standard owns those meanings and the resulting mark.

These works further define FoldKernel by demonstrating what its verified
relations can support. They do not alter the contract, become generic
templates, or transfer their authorship to FoldKernel.

## Conformance and interchange

The normative [relation-weight vector](Tests/FoldKernelTests/Resources/relation-weight-vectors.json)
fixes observations (including a duplicate), canonical bytes, identity, weights,
and node masses. The [relation-map JSON schema](Integration/foldkernel-relation-map.schema.json)
defines the serialized output shape. Schema validation alone does not prove
canonical ordering, uniqueness by relation key or node identity, correct masses,
or identity: verifiers must derive the map from admitted observations and compare.

Uniqueness uses the complete `(source, target, kind, evidence)` tuple; the same
evidence digest may support distinct directed relations. All strings are ASCII,
so lexicographic ordering is unsigned byte order. Relations sort by source,
target, then kind; nodes sort by identity. Counts above `UInt32.max` unique
observations throw `observationCountOverflow` before encoding or accumulation.
An edge weight and any node mass cannot exceed this bound because self-relations
are rejected. `encode` is throwing; it permits the zero-count byte representation,
while `derive` rejects an empty map. Codable decoding is structural only; it does
not validate a claimed map against evidence.

CI checks the vector against the Swift implementation and validates its expected
map against the schema. The library builds with Swift 5.9; the test suite uses
Swift Testing and runs with Swift 6.1.2 in Swift 5 language mode.

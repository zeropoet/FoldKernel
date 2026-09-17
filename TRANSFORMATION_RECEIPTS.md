# FoldKernel Transformation Receipt 1.0

`FoldKernel-Transformation-Receipt-1.0.0` records consequential change without
destroying or replacing the source artifact. It is an additive preservation
contract and does not alter FoldKernel convergence hashes.

The allowed transition kinds are `transformed`, `fulfilled`, `consumed`,
`superseded`, and `retired`. A transformed or fulfilled source must identify a
distinct derived output. Consumption, supersession, and retirement may record
consequence without pretending that a new artifact exists.

Every receipt commits to source identity, transition, optional output identity,
evidence, and date. Version 1.0 requires the source to remain preserved and is
always non-destructive, non-transferable, non-purchasable, non-appreciating,
non-monetary, and free of personal data. A receipt cannot itself create money or
authorize deletion.

The receipt identity is Keccak-256 over a byte encoding independent of JSON key
order. Text uses an unsigned 32-bit big-endian UTF-8 length followed by UTF-8
bytes. Digests use their 32 raw bytes. Optional fields begin with `0x00` when
absent or `0x01` followed by their encoding when present. Fields are encoded in
this order:

```text
contract version
digest algorithm
source system
event ID
source artifact digest
source kind
transition kind
optional output artifact digest
optional output kind
evidence digest
occurrence date
source-preserved, destructive, transferable, purchasable, appreciating,
monetary, personal-data flags
```

The schema lives at
[`Integration/foldkernel-transformation-receipt.schema.json`](Integration/foldkernel-transformation-receipt.schema.json).
Telos may verify a receipt and apply a separately governed operational-capacity
policy. That policy cannot alter the receipt, transfer its consequence, or
convert internal capacity into money.

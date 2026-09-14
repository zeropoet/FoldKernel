# FoldKernel Value Receipt 1.0

`FoldKernel-Value-Receipt-1.0.0` is the deterministic bridge between useful
system work and an externally evidenced monetary counterpart. It does not mint
money, price artifacts, custody funds, or modify the FoldKernel convergence
protocol.

The lifecycle is strictly linear:

```text
unrealized -> evidenced -> realized -> settled
```

- `unrealized` records a coherent output without assigning money.
- `evidenced` records that the output has admissible work evidence, still
  without assigning money.
- `realized` requires positive USD cents, an allowed valuation basis, and an
  external SHA-256 evidence digest.
- `settled` preserves the realized amount exactly and adds an external
  settlement evidence digest.

Every transition creates a new Keccak-256 receipt identity and names the prior
receipt. Work identity and period cannot change inside a chain. Version 1.0
receipts are always non-transferable, non-purchasable, non-appreciating, and
free of personal data.

The receipt digest is Keccak-256 over a byte encoding independent of JSON key
order. Text values are encoded as an unsigned 32-bit big-endian UTF-8 byte
length followed by UTF-8 bytes. Digests are their 32 raw bytes. Optional values
begin with `0x00` when absent or `0x01` followed by their encoding when present.
Integer cents use unsigned 64-bit big-endian form. Fields are encoded in this
order:

```text
contract version
digest algorithm
source system
event ID
artifact digest
output kind
period start
period end
state
valuation basis
optional currency
optional monetary counterpart cents
optional valuation evidence digest
optional settlement evidence digest
optional prior receipt ID
transferable, purchasable, appreciating, personal-data flags
```

The four terminal flags are each encoded as `0x00` in 1.0. The schema lives at
[`Integration/foldkernel-value-receipt.schema.json`](Integration/foldkernel-value-receipt.schema.json).
The Swift API issues, advances, verifies, and transition-checks receipts through
`FoldKernelValueReceiptContract`.

Telos may verify and observe a valid public receipt chain. It may not create an
application's work evidence, invent a monetary counterpart, alter a realized
amount during settlement, or treat observed receipt amounts as additional
ledger revenue.

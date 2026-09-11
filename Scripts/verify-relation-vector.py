"""Independent relation contract check. Dependencies are pinned in CI."""
import copy
import json
from collections import Counter
from pathlib import Path

from Crypto.Hash import keccak
from jsonschema import Draft202012Validator

root = Path(__file__).resolve().parents[1]
schema = json.loads((root / "Integration/foldkernel-relation-map.schema.json").read_text())
vector = json.loads((root / "Tests/FoldKernelTests/Resources/relation-weight-vectors.json").read_text())
Draft202012Validator.check_schema(schema)
validator = Draft202012Validator(schema)
validator.validate(vector["expected"])
for invalid_kind in ["informs\n", "", "Informs", "é", "a" * 65]:
    invalid = copy.deepcopy(vector["expected"])
    invalid["relations"][0]["kind"] = invalid_kind
    assert not validator.is_valid(invalid), invalid_kind
fields = ("sourceIdentity", "targetIdentity", "kind", "evidenceDigest")
observations = sorted({tuple(o[k] for k in fields) for o in vector["observations"]})
encoded = b"FoldKernel-Relation-1.1.0" + len(observations).to_bytes(4, "big")
edges = Counter()
nodes = Counter()
for source, target, kind, evidence in observations:
    assert source != target
    encoded += bytes.fromhex(source) + bytes.fromhex(target)
    encoded += len(kind.encode("ascii")).to_bytes(2, "big") + kind.encode("ascii")
    encoded += bytes.fromhex(evidence)
    edges[source, target, kind] += 1
    nodes[source] += 1
    nodes[target] += 1
expected = vector["expected"]
assert encoded.hex() == vector["canonicalBytesHex"]
assert keccak.new(digest_bits=256, data=encoded).hexdigest() == expected["relationMapID"]
assert len(observations) == expected["uniqueObservationCount"]
assert [dict(sourceIdentity=s, targetIdentity=t, kind=k, weight=w)
        for (s, t, k), w in sorted(edges.items())] == expected["relations"]
assert [dict(identity=i, mass=m) for i, m in sorted(nodes.items())] == expected["nodes"]
print("Relation schema, canonical bytes, Keccak identity, weights, and masses verified.")

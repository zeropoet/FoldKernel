#!/usr/bin/env bash
set -euo pipefail

expected='protocol=FoldKernel-1.0.0
permutation=13,3,2,16,8,10,11,5,12,6,7,9,1,15,14,4
memory_signature=010d030210080a0b050c060709010f0e0402070301
convergence_hash=dae462e1178f1670b8f7c207a78581316d51249dd5dff632df87a73cc0c029b8
canonical=true
sum_invariant=true
adjacency_invariant=true'

actual="$(swift run -c release fold-kernel-example)"

if [[ "$actual" != "$expected" ]]; then
  echo "FoldKernel developer preview output drifted." >&2
  diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") || true
  exit 1
fi

printf '%s\n' "FoldKernel developer preview verified."

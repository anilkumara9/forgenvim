#!/usr/bin/env bash
# Startup benchmark: 10 headless runs, reports median wall time for core load.
set -u
NVIM="${NVIM:-nvim}"; total=0; best=999999
for i in $(seq 1 10); do
  start=$(date +%s%N); FORGE_MINIMAL=1 "$NVIM" --headless -u "$(dirname "$0")/../init.lua" +qa 2>/dev/null; end=$(date +%s%N)
  ms=$(( (end-start)/1000000 )); echo "run $i: ${ms}ms"; [ "$ms" -lt "$best" ] && best=$ms; total=$((total+ms))
done
echo "mean: $((total/10))ms  best: ${best}ms  (core/minimal mode; full plugin load is lazy and measured with :Lazy profile)"

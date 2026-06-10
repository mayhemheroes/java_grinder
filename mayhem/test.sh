#!/usr/bin/env bash
# java_grinder/mayhem/test.sh — GOLDEN / known-answer oracle for java_grinder.
#
# java_grinder's OWN test suite (tests/run_tests.sh) compiles each test .class to asm, then assembles
# it with naken_asm and runs it under the naken_util CPU emulator (with hard-coded /home/mike/... paths)
# to check a computed result. Neither naken_asm nor naken_util is in the base image, so that suite is
# NOT self-contained. Instead we use the deterministic core of what java_grinder does — turning a known
# .class into assembly — as a self-contained golden oracle (NO JDK, assembler, or emulator at test time):
#
#   * mayhem/build.sh built /mayhem/java_grinder-tests with the project's NORMAL flags (NO sanitizer),
#     so the oracle exercises the real shipped behavior and never false-fails on benign UB the fuzz build
#     relaxes. This script only RUNS that binary — it never compiles (PATCH grading: patch -> build.sh -> test.sh).
#   * For each committed test class (mayhem/testdata/classes/<name>.class) it generates assembly for the
#     mips32 platform and DIFFs it against a committed golden (mayhem/testdata/golden/<name>.mips32.asm).
#     The .class inputs were compiled once with javac from tests/<name>.java; the goldens were captured
#     once from the normal-flags binary and verified byte-stable across repeated runs (the emitted asm
#     embeds no timestamps/paths/version, so it is reproducible).
#
# This is a PATCH-grade, anti-reward-hack oracle by construction: it asserts the EXACT generated
# assembly for each program (the constant pool, the per-bytecode codegen, the method prologues), not
# merely "exited 0". A no-op / exit(0) "patch", or any change that breaks the bytecode reader or a code
# generator so the emitted asm changes, FAILS the diff.
set -uo pipefail

# clang/gcc reject SOURCE_DATE_EPOCH='' (empty); must be unset or a valid integer.
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

# SRC is /mayhem in the commit image; default to this checkout's repo root so the suite also runs
# straight from a developer checkout (mayhem/ is one level below the repo root).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: "${SRC:=$(cd "$HERE/.." && pwd)}"
cd "$SRC"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
# Writes a CTRF report (file + stdout `CTRF {...}` marker) and returns non-zero iff failed>0.
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

# The normal-flags oracle binary that build.sh produced.
BIN="$SRC/java_grinder-tests"
[ -x "$BIN" ] || { echo "missing $BIN — run mayhem/build.sh first" >&2; emit_ctrf "java_grinder-golden" 0 1; exit 2; }

CLASSES="$SRC/mayhem/testdata/classes"
GOLDEN="$SRC/mayhem/testdata/golden"
[ -d "$GOLDEN" ] || { echo "missing golden dir $GOLDEN — wrong tree?" >&2; emit_ctrf "java_grinder-golden" 0 1; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

passed=0; failed=0

# run_case <name>
# Runs java_grinder on mayhem/testdata/classes/<name>.class for the mips32 platform, diffs the emitted
# assembly against mayhem/testdata/golden/<name>.mips32.asm. MUST exit 0 AND match the golden byte-for-byte.
run_case() {
  local name="$1"
  local cls="$CLASSES/$name.class" gold="$GOLDEN/$name.mips32.asm" got="$WORK/$name.asm" rc
  if [ ! -f "$cls" ]; then
    echo "FAIL $name: missing class $cls" >&2; failed=$((failed+1)); return
  fi
  if [ ! -f "$gold" ]; then
    echo "FAIL $name: missing golden $gold" >&2; failed=$((failed+1)); return
  fi
  # java_grinder prints a banner to stdout and writes the asm to the named output file (2nd arg).
  "$BIN" "$cls" "$got" mips32 > "$WORK/$name.log" 2>&1; rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "FAIL $name: java_grinder exited $rc (expected 0)" >&2
    sed 's/^/    /' "$WORK/$name.log" >&2
    failed=$((failed+1)); return
  fi
  if [ ! -f "$got" ]; then
    echo "FAIL $name: java_grinder produced no asm output" >&2; failed=$((failed+1)); return
  fi
  if diff -u "$gold" "$got" > "$WORK/$name.diff" 2>&1; then
    echo "PASS $name"; passed=$((passed+1))
  else
    echo "FAIL $name: emitted asm differs from golden" >&2
    head -30 "$WORK/$name.diff" | sed 's/^/    /' >&2
    failed=$((failed+1))
  fi
}

# Deterministic test classes (compiled once from tests/<name>.java). Each exercises a distinct bytecode
# path: integer mul/div, if/else branching, a loop, a ternary, null handling, statics.
run_case Multiply    # static int multiply
run_case Divide      # static int divide
run_case IfElse      # nested if/else branching
run_case LoopTest    # for-loop down-counter
run_case Ternary_1   # ternary expression
run_case NotNull     # null-check elision
run_case Statics     # static field access
run_case Testing     # mixed arithmetic

emit_ctrf "java_grinder-golden" "$passed" "$failed"

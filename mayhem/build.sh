#!/usr/bin/env bash
# java_grinder/mayhem/build.sh — build java_grinder (a C++ tool that compiles Java .class/.jar
# bytecode into assembly for retro CPUs) as the fuzz target, plus a clean normal-flags build of the
# same tool for the self-contained golden-asm test oracle (mayhem/test.sh).
#
# java_grinder builds via a recursive Makefile: the top-level `make` runs `make -C build`, which
# compiles every api/common/generator .cxx into build/ and links ./java_grinder. The Mayhem target is
# FILE-INPUT (CLI): `java_grinder @@ out amiga` runs the tool on the fuzz bytes as a Java .class file
# and emits assembly for the `amiga` platform (the old integration's target). The natural fuzz surface
# is the bytecode reader + code generator on a .class file — no libFuzzer harness, so the ELF is its
# own reproducer (no -standalone needed).
#
# build/Makefile bakes CFLAGS=-Wall -O3 -std=c++11 -DDEBUG -g -I.. and links via $(CXX). We override
# CFLAGS on the make command line to inject $SANITIZER_FLAGS while preserving the REQUIRED bits
# (-std=c++11 and -I.. — without -I.. the api/common/generator headers don't resolve).
#
# Two builds from the same in-tree Makefile (it builds in build/ and links ./java_grinder, so the two
# builds can't coexist — run sequentially with a clean in between):
#   (1) NORMAL-flags build -> /mayhem/java_grinder-tests   (honest oracle for test.sh; no sanitizer noise)
#   (2) SANITIZED build     -> /mayhem/java_grinder         (the file-input fuzz target)
set -euo pipefail

# clang rejects SOURCE_DATE_EPOCH='' (empty) — must be unset or a valid integer.
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

# Build knobs from the ENV, overridable. SANITIZER_FLAGS uses `=` (not `:=`) so an explicit empty value
# (--build-arg SANITIZER_FLAGS=) is honored → no-sanitizer build (the tool's natural crash). java_grinder
# links no external libs, so the empty-sanitizer build links cleanly with no extra flags.
: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer -g}"
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${CC:=clang}" ; : "${CXX:=clang++}"
: "${MAYHEM_JOBS:=$(nproc)}"
export SANITIZER_FLAGS DEBUG_FLAGS CC CXX MAYHEM_JOBS

cd "$SRC"

# REQUIRED compile bits the project's build depends on (must survive our CFLAGS override):
#   -std=c++11  the codebase is C++11; -I..  resolves api/common/generator headers from build/.
REQUIRED_CFLAGS="-std=c++11 -I.."

# ---------------------------------------------------------------------------
# (1) TEST build — java_grinder's OWN flags (-O3, no sanitizer). Stashed at /mayhem/java_grinder-tests
#     so test.sh runs the real shipped behavior and never false-falls on benign UB. Built first, then
#     the tree is cleaned for the sanitized build (the Makefile is in-tree; the two can't coexist).
# ---------------------------------------------------------------------------
make clean >/dev/null 2>&1 || true
make -j"$MAYHEM_JOBS" CC="$CC" CXX="$CXX" CFLAGS="-Wall -O3 $REQUIRED_CFLAGS"
cp -f java_grinder /mayhem/java_grinder-tests
echo "build.sh: test-oracle java_grinder -> /mayhem/java_grinder-tests"

# ---------------------------------------------------------------------------
# (2) FUZZ build — the TOOL itself compiled WITH $SANITIZER_FLAGS so the fuzzed code (bytecode reader +
#     code generators) is instrumented (ASan+UBSan, halting, by default). The file-input Mayhem target
#     lands at /mayhem/java_grinder.
# ---------------------------------------------------------------------------
# Relax ONE benign UBSan check that java_grinder trips on EVERY input (PORTING.md "benign UB that floods
# under halting UBSan"):
#   * alignment — common/JavaClass.cxx reads the whole class file's constant pool into one malloc'd byte
#                 buffer (constants_heap) and casts arbitrary offsets within it to packed structs
#                 (generic_twoint16_t / _32bit_t / _64bit_t / constant_utf8_t / constant_class_t), then
#                 accesses their multi-byte members. On x86 these unaligned loads are well-defined, but
#                 UBSan's alignment check fires on essentially every constant-pool entry of every .class
#                 file — aborting before the fuzzer can explore any real defect (it floods the default
#                 seeds too). Relaxed ONLY when UBSan is active (skipped for the empty-sanitizer
#                 off-switch). ASan and the REST of UBSan stay ON and HALTING, so real memory/UB defects
#                 in the bytecode reader and code generators still crash the fuzzer. Smoke-tested: a
#                 valid .class then runs to exit 0.
UBSAN_RELAX=""
if printf '%s' "$SANITIZER_FLAGS" | grep -q undefined; then
  UBSAN_RELAX="-fno-sanitize=alignment"
fi

make clean >/dev/null 2>&1 || true
make -j"$MAYHEM_JOBS" CC="$CC" CXX="$CXX" CFLAGS="-Wall $SANITIZER_FLAGS $UBSAN_RELAX $DEBUG_FLAGS $REQUIRED_CFLAGS"
# The Makefile links ./java_grinder in $SRC. In the commit image $SRC == /mayhem, so the fuzz target
# is already at /mayhem/java_grinder; only copy when building from a checkout elsewhere.
[ "$SRC/java_grinder" -ef /mayhem/java_grinder ] || cp -f "$SRC/java_grinder" /mayhem/java_grinder

echo "build.sh: built /mayhem/java_grinder (sanitized fuzz target) and /mayhem/java_grinder-tests (test oracle)"
ls -l /mayhem/java_grinder /mayhem/java_grinder-tests

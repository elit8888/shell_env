#!/usr/bin/env bash
# Tests for unzip_7z.sh (single .7z / .7z.001)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

pass() { echo "PASS: $1"; (( PASS++ )) || true; }
fail() { echo "FAIL: $1"; (( FAIL++ )) || true; }

assert_file_exists() {
  if [ -f "$2" ]; then pass "$1"; else fail "$1 — file not found: $2"; fi
}

assert_file_missing() {
  if [ ! -e "$2" ]; then pass "$1"; else fail "$1 — still exists: $2"; fi
}

# Usage: make_archive <type> <archive_path> <member>
make_archive() {
  local type="$1" archive="$2" member="$3"
  local stage
  stage="$(mktemp -d)"
  printf 'hello' > "$stage/$member"
  7z a -t"$type" "$archive" "$stage/$member" > /dev/null
  rm -rf "$stage"
}

# Usage: make_volumes <archive_path.7z> -> archive_path.7z.001 .002 .003
make_volumes() {
  local stage
  stage="$(mktemp -d)"
  head -c 300000 /dev/urandom > "$stage/big.bin"
  7z a -t7z -v100k "$1" "$stage/big.bin" > /dev/null
  rm -rf "$stage"
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  case "$haystack" in
    *"$needle"*) pass "$desc" ;;
    *) fail "$desc"; echo "  missing: $needle" ;;
  esac
}

# --- Test 1: single .7z extracted into same-name folder, original kept ---
echo "=== Test 1: unzip_7z.sh ==="
T1="$TMPDIR/t1"
mkdir -p "$T1"
make_archive 7z "$T1/my archive.7z" "a.txt"

pushd "$T1" > /dev/null
echo | bash "$SCRIPT_DIR/unzip_7z.sh" "my archive.7z" > /dev/null
popd > /dev/null

assert_file_exists "7z extracted to same-name folder" "$T1/my archive/a.txt"
assert_file_exists "single-file original kept" "$T1/my archive.7z"

# --- Test 2: single multi-volume .7z.001 extracted into base-name folder ---
echo ""
echo "=== Test 2: unzip_7z.sh multi-volume ==="
T2="$TMPDIR/t2"
mkdir -p "$T2"
make_volumes "$T2/vol.7z"

pushd "$T2" > /dev/null
echo | bash "$SCRIPT_DIR/unzip_7z.sh" "vol.7z.001" > /dev/null
popd > /dev/null

assert_file_exists "volumes extracted to base-name folder" "$T2/vol/big.bin"
assert_file_exists "single-file volumes kept" "$T2/vol.7z.002"

# --- Test 3: .001 that is not a 7z volume is rejected ---
echo ""
echo "=== Test 3: unzip_7z.sh rejects non-7z .001 ==="
T3="$TMPDIR/t3"
mkdir -p "$T3"
make_archive zip "$T3/other.zip" "o.txt"
mv "$T3/other.zip" "$T3/other.zip.001"

pushd "$T3" > /dev/null
out="$(echo | bash "$SCRIPT_DIR/unzip_7z.sh" "other.zip.001" 2>&1)"
popd > /dev/null

assert_contains "reports unsupported volume" "ERROR" "$out"
assert_file_missing "nothing extracted" "$T3/other.zip"

# --- Summary ---
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

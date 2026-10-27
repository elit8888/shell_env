#!/usr/bin/env bash
# Tests for scale_all / elit_scale (folder background "scale all jpg")
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

pass() { echo "PASS: $1"; (( PASS++ )) || true; }
fail() { echo "FAIL: $1"; (( FAIL++ )) || true; }

assert_exists() {
  local desc="$1" path="$2"
  if [ -e "$path" ]; then pass "$desc"; else fail "$desc — not found: $path"; fi
}

assert_missing() {
  local desc="$1" path="$2"
  if [ ! -e "$path" ]; then pass "$desc"; else fail "$desc — still exists: $path"; fi
}

assert_width() {
  local desc="$1" path="$2" want="$3" w
  w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$path" 2>/dev/null || true)
  [ "$w" = "$want" ] && pass "$desc" || fail "$desc — width '$w', want $want"
}

make_img() {
  mkdir -p "$(dirname "$1")"
  ffmpeg -y -v error -f lavfi -i color=c=red:s=16x16 -frames:v 1 "$1"
}

make_tree() {
  make_img "$1/a.jpg"
  make_img "$1/sub/b.jpg"
  make_img "$1/sub/deep/c.jpg"
  make_img "$1/by4/old.jpg"
}

# --- Test 1: non-recursive only scales top-level files ---
echo "=== Test 1: scale_all non-recursive ==="
T="$TMPDIR/flat"
make_tree "$T"
pushd "$T" > /dev/null
scale_all 2 > /dev/null
popd > /dev/null
assert_width   "flat: top-level scaled"   "$T/by2/a.jpg" 8
assert_missing "flat: sub not scaled"     "$T/by2/sub"

# --- Test 2: recursive keeps structure under top-level by<f>/ ---
echo "=== Test 2: scale_all recursive ==="
T="$TMPDIR/rec"
make_tree "$T"
pushd "$T" > /dev/null
scale_all 2 true > /dev/null
popd > /dev/null
assert_width   "rec: top-level"           "$T/by2/a.jpg" 8
assert_width   "rec: sub"                 "$T/by2/sub/b.jpg" 8
assert_width   "rec: sub/deep"            "$T/by2/sub/deep/c.jpg" 8
assert_missing "rec: no per-folder output" "$T/sub/by2"
assert_missing "rec: old by4/ skipped"    "$T/by2/by4"

# --- Test 3: re-running does not rescale its own output ---
echo "=== Test 3: rerun ignores by<f>/ ==="
pushd "$T" > /dev/null
scale_all 2 true > /dev/null
popd > /dev/null
assert_missing "rerun: no by2/by2"        "$T/by2/by2"

# --- Test 4: elit_scale asks only when subfolders exist ---
echo "=== Test 4: elit_scale prompt ==="
T="$TMPDIR/prompt"
make_tree "$T"
pushd "$T" > /dev/null
out=$(printf 'y\n\n' | elit_scale 2 2>&1)
popd > /dev/null
[[ "$out" == *"recursive: true"* ]] && pass "prompt: y -> recursive" || fail "prompt: output was '$out'"
assert_exists "prompt: sub scaled" "$T/by2/sub/b.jpg"

T="$TMPDIR/prompt_no"
make_tree "$T"
pushd "$T" > /dev/null
out=$(printf '\n\n' | elit_scale 2 2>&1)
popd > /dev/null
[[ "$out" == *"recursive: false"* ]] && pass "prompt: default -> not recursive" || fail "prompt: output was '$out'"
assert_missing "prompt: sub not scaled" "$T/by2/sub"

T="$TMPDIR/nosub"
make_img "$T/a.jpg"
make_img "$T/by2/x.jpg"
pushd "$T" > /dev/null
out=$(printf '\n' | elit_scale 2 2>&1)
popd > /dev/null
[[ "$out" != *"Include subfolders"* ]] && pass "nosub: no prompt" || fail "nosub: output was '$out'"
assert_width "nosub: scaled" "$T/by2/a.jpg" 8

# --- Test 5: empty folder reports ---
echo "=== Test 5: no jpg ==="
mkdir -p "$TMPDIR/empty"
pushd "$TMPDIR/empty" > /dev/null
out=$(scale_all 2)
popd > /dev/null
[[ "$out" == *"No .jpg files found."* ]] && pass "empty: message" || fail "empty: output was '$out'"
assert_missing "empty: no output dir" "$TMPDIR/empty/by2"

# --- Summary ---
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

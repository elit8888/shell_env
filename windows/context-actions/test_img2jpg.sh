#!/usr/bin/env bash
# Tests for img2jpg (png / webp / jpeg -> jpg)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

pass() { echo "PASS: $1"; (( PASS++ )) || true; }
fail() { echo "FAIL: $1"; (( FAIL++ )) || true; }

assert_jpg() {
  local desc="$1" path="$2"
  if [ -f "$path" ] && [ "$(xxd -l 3 -p "$path")" = "ffd8ff" ]; then
    pass "$desc"
  else
    fail "$desc — not a jpg: $path"
  fi
}

assert_missing() {
  local desc="$1" path="$2"
  if [ ! -e "$path" ]; then pass "$desc"; else fail "$desc — still exists: $path"; fi
}

assert_exists() {
  local desc="$1" path="$2"
  if [ -e "$path" ]; then pass "$desc"; else fail "$desc — not found: $path"; fi
}

make_img() {
  ffmpeg -y -v error -f lavfi -i color=c=red:s=8x8 -frames:v 1 "$1"
}

# --- Test 1: single-file converter handles each source format ---
echo "=== Test 1: img2jpg_ single file ==="
for ext in png webp jpeg; do
  make_img "$TMPDIR/one_$ext.$ext"
  img2jpg_ "$TMPDIR/one_$ext.$ext"
  assert_jpg "single $ext -> jpg" "$TMPDIR/one_$ext.jpg"
done

# --- Test 2: batch converts all three formats (case-insensitive, recursive) ---
echo "=== Test 2: img2jpg batch ==="
BATCH="$TMPDIR/batch"
mkdir -p "$BATCH/sub"
make_img "$BATCH/a.png"
make_img "$BATCH/b.webp"
make_img "$BATCH/sub/c.jpeg"
make_img "$BATCH/D.PNG"
make_img "$BATCH/keep.gif"

ELIT_DELETE_ORIGINAL=true
pushd "$BATCH" > /dev/null
img2jpg > /dev/null
popd > /dev/null

assert_jpg "batch png"        "$BATCH/a.jpg"
assert_jpg "batch webp"       "$BATCH/b.jpg"
assert_jpg "batch jpeg (sub)" "$BATCH/sub/c.jpg"
assert_jpg "batch PNG upper"  "$BATCH/D.jpg"
assert_missing "png removed"  "$BATCH/a.png"
assert_missing "webp removed" "$BATCH/b.webp"
assert_missing "jpeg removed" "$BATCH/sub/c.jpeg"
assert_exists  "gif untouched" "$BATCH/keep.gif"
assert_missing "gif not converted" "$BATCH/keep.jpg"

# --- Test 3: ELIT_DELETE_ORIGINAL=false keeps originals ---
echo "=== Test 3: keep originals ==="
KEEP="$TMPDIR/keep"
mkdir -p "$KEEP"
make_img "$KEEP/k.webp"
ELIT_DELETE_ORIGINAL=false
pushd "$KEEP" > /dev/null
img2jpg > /dev/null
popd > /dev/null
assert_jpg    "keep: jpg created"    "$KEEP/k.jpg"
assert_exists "keep: original kept"  "$KEEP/k.webp"

# --- Test 4: empty folder reports and returns non-zero ---
echo "=== Test 4: no matching files ==="
EMPTY="$TMPDIR/empty"
mkdir -p "$EMPTY"
pushd "$EMPTY" > /dev/null
if out=$(img2jpg); then
  fail "empty: expected non-zero exit"
else
  pass "empty: non-zero exit"
fi
popd > /dev/null
[[ "$out" == *"No .png/.webp/.jpeg files found."* ]] && pass "empty: message" || fail "empty: message was '$out'"

# --- Summary ---
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

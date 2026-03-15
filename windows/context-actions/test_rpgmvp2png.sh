#!/usr/bin/env bash
# Tests for rpgmvp2png conversion
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $desc"
    (( PASS++ )) || true
  else
    echo "FAIL: $desc"
    echo "  expected: $expected"
    echo "  actual:   $actual"
    (( FAIL++ )) || true
  fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  if [ -f "$path" ]; then
    echo "PASS: $desc"
    (( PASS++ )) || true
  else
    echo "FAIL: $desc — file not found: $path"
    (( FAIL++ )) || true
  fi
}

# Create a fake rpgmvp file: 32 bytes of junk + real PNG data after header
create_fake_rpgmvp() {
  local out="$1"
  # 32 bytes of padding (RPG Maker MV header)
  dd if=/dev/zero bs=1 count=32 2>/dev/null > "$out"
  # Append some fake "PNG body" data (after the IHDR chunk start)
  printf 'FAKEPNGBODYDATA' >> "$out"
}

# --- Test 1: Single file conversion (rpgmvp) ---
echo "=== Test 1: Single file rpgmvp2png_ ==="
create_fake_rpgmvp "$TMPDIR/test.rpgmvp"
rpgmvp2png_ "$TMPDIR/test.rpgmvp"
assert_file_exists "output .png created" "$TMPDIR/test.png"
# Verify PNG header (first 8 bytes)
header=$(xxd -l 8 -p "$TMPDIR/test.png")
assert_eq "PNG signature" "89504e470d0a1a0a" "$header"
# Verify IHDR bytes (bytes 9-16)
ihdr=$(xxd -s 8 -l 8 -p "$TMPDIR/test.png")
assert_eq "IHDR chunk marker" "0000000d49484452" "$ihdr"
# Verify body data is appended after the 16-byte header
body=$(xxd -s 16 -l 15 -p "$TMPDIR/test.png")
expected_body=$(printf 'FAKEPNGBODYDATA' | xxd -p)
assert_eq "body data preserved" "$expected_body" "$body"

# --- Test 2: Single file with custom output path ---
echo ""
echo "=== Test 2: Single file with custom output ==="
create_fake_rpgmvp "$TMPDIR/test2.rpgmvp"
mkdir -p "$TMPDIR/custom"
rpgmvp2png_ "$TMPDIR/test2.rpgmvp" "$TMPDIR/custom/out.png"
assert_file_exists "custom output path works" "$TMPDIR/custom/out.png"

# --- Test 3: Single file conversion (png_) ---
echo ""
echo "=== Test 3: Single file png_ extension ==="
create_fake_rpgmvp "$TMPDIR/test3.png_"
rpgmvp2png_ "$TMPDIR/test3.png_"
assert_file_exists "png_ -> .png created" "$TMPDIR/test3.png"

# --- Test 4: Batch conversion with directory structure ---
echo ""
echo "=== Test 4: Batch conversion ==="
BATCHDIR="$TMPDIR/batch"
mkdir -p "$BATCHDIR/a/b"
create_fake_rpgmvp "$BATCHDIR/root.rpgmvp"
create_fake_rpgmvp "$BATCHDIR/a/mid.rpgmvp"
create_fake_rpgmvp "$BATCHDIR/a/b/deep.png_"

ELIT_DELETE_ORIGINAL=false
pushd "$BATCHDIR" > /dev/null
rpgmvp2png
popd > /dev/null

assert_file_exists "batch: root file" "$BATCHDIR/png/root.png"
assert_file_exists "batch: mid file" "$BATCHDIR/png/a/mid.png"
assert_file_exists "batch: deep file" "$BATCHDIR/png/a/b/deep.png"
# Verify originals still exist (ELIT_DELETE_ORIGINAL=false)
assert_file_exists "batch: original preserved" "$BATCHDIR/root.rpgmvp"

# --- Test 5: Batch conversion with delete ---
echo ""
echo "=== Test 5: Batch with delete original ==="
DELDIR="$TMPDIR/deltest"
mkdir -p "$DELDIR"
create_fake_rpgmvp "$DELDIR/del.rpgmvp"

ELIT_DELETE_ORIGINAL=true
pushd "$DELDIR" > /dev/null
rpgmvp2png
popd > /dev/null

assert_file_exists "delete: output created" "$DELDIR/png/del.png"
if [ ! -f "$DELDIR/del.rpgmvp" ]; then
  echo "PASS: delete: original removed"
  (( PASS++ )) || true
else
  echo "FAIL: delete: original still exists"
  (( FAIL++ )) || true
fi

# --- Summary ---
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

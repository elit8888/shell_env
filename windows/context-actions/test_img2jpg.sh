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

# --- Test 5: animated webp is skipped (single + batch) ---
echo "=== Test 5: animated webp skipped ==="
make_anim_webp() {
  ffmpeg -y -v error -f lavfi -i testsrc=size=16x16:rate=5:duration=1 \
    -c:v libwebp_anim -loop 0 "$1"
}
ANIM="$TMPDIR/anim"
mkdir -p "$ANIM"
make_anim_webp "$ANIM/one.webp"
if out=$(img2jpg_ "$ANIM/one.webp" 2>&1); then
  fail "anim single: expected non-zero exit"
else
  pass "anim single: non-zero exit"
fi
[[ "$out" == *"skip animated: $ANIM/one.webp"* ]] && pass "anim single: message" || fail "anim single: message was '$out'"
assert_missing "anim single: no jpg"        "$ANIM/one.jpg"
assert_exists  "anim single: original kept" "$ANIM/one.webp"

printf 'x' > "$ANIM/tiny.png"
out=$(img2jpg_ "$ANIM/tiny.png" 2>&1) || true
[[ "$out" != *"od:"* ]] && pass "tiny file: no od error" || fail "tiny file: output was '$out'"

ANIMB="$TMPDIR/anim_batch"
mkdir -p "$ANIMB"
make_anim_webp "$ANIMB/moving.webp"
make_img "$ANIMB/still.webp"
ELIT_DELETE_ORIGINAL=true
pushd "$ANIMB" > /dev/null
img2jpg > /dev/null
popd > /dev/null
assert_missing "anim batch: no jpg"           "$ANIMB/moving.jpg"
assert_exists  "anim batch: original kept"    "$ANIMB/moving.webp"
assert_jpg     "anim batch: static converted" "$ANIMB/still.jpg"
assert_missing "anim batch: static removed"   "$ANIMB/still.webp"

# --- Test 6: batch prints skip / error messages after all progress lines ---
echo "=== Test 6: batch messages deferred to end ==="
MSG="$TMPDIR/msg"
mkdir -p "$MSG"
make_anim_webp "$MSG/moving.webp"
echo "not an image" > "$MSG/bad.png"
make_img "$MSG/a.png"
make_img "$MSG/b.png"
ELIT_DELETE_ORIGINAL=true
pushd "$MSG" > /dev/null
out=$(img2jpg 2>&1)
popd > /dev/null
HEADER="=== Warnings / errors ==="
before="${out%%"$HEADER"*}"
after="${out#*"$HEADER"}"
[[ "$out" == *"$HEADER"* ]] && pass "msg: header printed" || fail "msg: no header in '$out'"
[[ "$before" != *"skip animated"* ]] && pass "msg: no skip before header" || fail "msg: skip printed early"
[[ "$before" != *"Invalid data"* ]] && pass "msg: no ffmpeg error before header" || fail "msg: ffmpeg error printed early"
[[ "$after" == *"skip animated: ./moving.webp"* ]] && pass "msg: skip in summary" || fail "msg: summary was '$after'"
[[ "$after" == *"./bad.png"* && "$after" == *"Invalid data"* ]] && pass "msg: ffmpeg error in summary" || fail "msg: summary was '$after'"
[[ "$after" != *"./a.png"* ]] && pass "msg: successes not in summary" || fail "msg: success listed in summary"
assert_exists "msg: bad original kept" "$MSG/bad.png"
assert_jpg    "msg: good converted"    "$MSG/a.jpg"

# --- Test 7: clean batch prints no summary header ---
echo "=== Test 7: clean batch has no summary ==="
CLEAN="$TMPDIR/clean"
mkdir -p "$CLEAN"
make_img "$CLEAN/a.png"
pushd "$CLEAN" > /dev/null
out=$(img2jpg 2>&1)
popd > /dev/null
[[ "$out" != *"$HEADER"* ]] && pass "clean: no header" || fail "clean: unexpected header in '$out'"

# --- Test 8: transparent areas become dark gray ---
echo "=== Test 8: transparency -> dark gray ==="
ALPHA="$TMPDIR/alpha"
mkdir -p "$ALPHA"
ffmpeg -y -v error -f lavfi -i "color=c=red@0.0:s=8x8,format=rgba" -frames:v 1 "$ALPHA/t.png"
img2jpg_ "$ALPHA/t.png"
px=$(ffmpeg -v error -i "$ALPHA/t.jpg" -f rawvideo -pix_fmt rgb24 -frames:v 1 - | head -c3 | od -An -tu1 | tr -s ' ')
read -r r g b <<< "$px"
(( r >= 28 && r <= 36 && g >= 28 && g <= 36 && b >= 28 && b <= 36 )) \
  && pass "alpha: transparent -> gray" || fail "alpha: pixel was '$px'"

# --- Test 9: existing jpg is not overwritten and original is kept ---
echo "=== Test 9: existing jpg skipped ==="
EXIST="$TMPDIR/exist"
mkdir -p "$EXIST"
make_img "$EXIST/a.png"
make_img "$EXIST/a.webp"
ELIT_DELETE_ORIGINAL=true
pushd "$EXIST" > /dev/null
out=$(img2jpg 2>&1)
popd > /dev/null
assert_jpg "exist: one jpg created" "$EXIST/a.jpg"
[[ -e "$EXIST/a.png" || -e "$EXIST/a.webp" ]] && pass "exist: skipped original kept" || fail "exist: both originals removed"
[[ "$out" == *"skip exists: ./a.jpg"* ]] && pass "exist: skip in summary" || fail "exist: output was '$out'"

# --- Summary ---
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

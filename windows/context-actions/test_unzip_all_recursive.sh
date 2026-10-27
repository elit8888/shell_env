#!/usr/bin/env bash
# Tests for unzip_all_recursive (recursive zip/rar/7z extraction)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

PASS=0
FAIL=0

pass() { echo "PASS: $1"; (( PASS++ )) || true; }
fail() { echo "FAIL: $1"; (( FAIL++ )) || true; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$desc"
  else
    fail "$desc"
    echo "  expected: $expected"
    echo "  actual:   $actual"
  fi
}

assert_file_exists() {
  if [ -f "$2" ]; then pass "$1"; else fail "$1 — file not found: $2"; fi
}

assert_file_missing() {
  if [ ! -e "$2" ]; then pass "$1"; else fail "$1 — still exists: $2"; fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  case "$haystack" in
    *"$needle"*) pass "$desc" ;;
    *) fail "$desc"; echo "  missing: $needle" ;;
  esac
}

# Build a zip containing a single text file
make_zip() {
  local zip_path="$1" member="$2"
  local stage
  stage="$(mktemp -d)"
  printf 'hello' > "$stage/$member"
  mkdir -p "$(dirname "$zip_path")"
  7z a -tzip "$zip_path" "$stage/$member" > /dev/null
  rm -rf "$stage"
}

# Build a zip whose member name ($3) is raw $2-encoded bytes with no UTF-8 flag,
# i.e. what a Japanese (cp932) / Korean (cp949) Windows tool produces. Written with
# an ASCII placeholder of identical byte length, then patched in place so sizes/CRCs stay valid.
make_legacy_zip() {
  python3 - "$1" "$2" "$3" <<'PY'
import sys, zipfile
zip_path, encoding, name = sys.argv[1:4]
raw = name.encode(encoding)
placeholder = "A" * (len(raw) - 4) + ".txt"    # same byte length, so offsets hold
with zipfile.ZipFile(zip_path, "w") as z:
    z.writestr(placeholder, "hello")
data = open(zip_path, "rb").read()
open(zip_path, "wb").write(data.replace(placeholder.encode("ascii"), raw))
PY
}

# --- Test 1: recursive extraction into per-archive folders ---
echo "=== Test 1: recursive extraction ==="
T1="$TMPDIR/t1"
mkdir -p "$T1/sub/deep"
make_zip "$T1/root.zip" "root.txt"
make_zip "$T1/sub/mid.zip" "mid.txt"
make_zip "$T1/sub/deep/deep.zip" "deep.txt"

ELIT_DELETE_ORIGINAL=true
pushd "$T1" > /dev/null
unzip_all_recursive > /dev/null
rc=$?
popd > /dev/null

assert_eq "returns 0 on success" "0" "$rc"
assert_file_exists "root archive extracted"  "$T1/root/root.txt"
assert_file_exists "nested archive extracted" "$T1/sub/mid/mid.txt"
assert_file_exists "deep archive extracted"   "$T1/sub/deep/deep/deep.txt"
assert_file_missing "original deleted after success" "$T1/root.zip"

# --- Test 2: failures are recorded and skipped, the rest still processed ---
echo ""
echo "=== Test 2: continue on error ==="
T2="$TMPDIR/t2"
mkdir -p "$T2"
printf 'not an archive at all' > "$T2/a_broken.rar"
printf 'not a zip either' > "$T2/b_broken.zip"
make_zip "$T2/z_good.zip" "good.txt"

pushd "$T2" > /dev/null
out="$(unzip_all_recursive 2>&1 <<< "n")"
rc=$?
popd > /dev/null

assert_eq "returns 1 when anything failed" "1" "$rc"
assert_file_exists "later archive still extracted" "$T2/z_good/good.txt"
assert_file_missing "later archive deleted" "$T2/z_good.zip"
assert_file_exists "failed rar kept" "$T2/a_broken.rar"
assert_file_exists "failed zip kept" "$T2/b_broken.zip"
assert_contains "summary counts" "Done. 1 archive(s) extracted, 2 failed." "$out"
summary="${out##*Failed:}"
assert_contains "summary lists failed rar" "./a_broken.rar" "$summary"
assert_contains "summary lists failed zip" "./b_broken.zip" "$summary"

# --- Test 3: no archives found ---
echo ""
echo "=== Test 3: no archives ==="
T3="$TMPDIR/t3"
mkdir -p "$T3"
printf 'x' > "$T3/plain.txt"

pushd "$T3" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0 when nothing to do" "0" "$rc"
assert_contains "reports nothing found" "No .zip, .rar or .7z files found." "$out"

# --- Test 4: keep originals when ELIT_DELETE_ORIGINAL=false ---
echo ""
echo "=== Test 4: keep originals ==="
T4="$TMPDIR/t4"
mkdir -p "$T4"
make_zip "$T4/keep.zip" "keep.txt"

ELIT_DELETE_ORIGINAL=false
pushd "$T4" > /dev/null
unzip_all_recursive > /dev/null
popd > /dev/null
ELIT_DELETE_ORIGINAL=true

assert_file_exists "extracted with keep flag" "$T4/keep/keep.txt"
assert_file_exists "original kept" "$T4/keep.zip"

# --- Test 5: multi-volume rar parts other than the first are skipped ---
echo ""
echo "=== Test 5: multi-volume rar ==="
T5="$TMPDIR/t5"
mkdir -p "$T5"
printf 'junk' > "$T5/movie.part2.rar"
printf 'junk' > "$T5/movie.part3.rar"

pushd "$T5" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "no error when only trailing parts exist" "0" "$rc"
assert_contains "skips part2" "SKIP" "$out"

# --- Test 6: zip goes through unzip_jp.py (via uv), so Shift-JIS names survive ---
echo ""
echo "=== Test 6: cp932 (Shift-JIS) filenames ==="
T6="$TMPDIR/t6"
mkdir -p "$T6/nested"
make_legacy_zip "$T6/nested/jp.zip" cp932 "テスト.txt"

pushd "$T6" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0 on cp932 zip" "0" "$rc"
assert_contains "fell back to cp932 decoding" "cp932" "$out"
assert_file_exists "Shift-JIS member extracted with correct name" "$T6/nested/jp/テスト.txt"

# --- Test 6b: cp949 (Korean) names; cp932 also decodes these bytes (as half-width kana) ---
echo ""
echo "=== Test 6b: cp949 (Korean) filenames ==="
T6B="$TMPDIR/t6b"
mkdir -p "$T6B"
make_legacy_zip "$T6B/kr.zip" cp949 "수영복.txt"

pushd "$T6B" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0 on cp949 zip" "0" "$rc"
assert_contains "picked cp949 decoding" "cp949" "$out"
assert_file_exists "Korean member extracted with correct name" "$T6B/kr/수영복.txt"

# --- Test 7: extracted paths longer than Windows MAX_PATH (260) ---
echo ""
echo "=== Test 7: long paths (> MAX_PATH) ==="
T7="$TMPDIR/t7"
mkdir -p "$T7"
LONG_MEMBER="$(printf 'a%.0s' {1..120})/$(printf 'b%.0s' {1..120})/long.txt"
python3 - "$T7/long.zip" "$LONG_MEMBER" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w") as z:
    z.writestr(sys.argv[2], "hello")
PY

pushd "$T7" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0 on long-path zip" "0" "$rc"
assert_file_exists "long-path member extracted" "$T7/long/$LONG_MEMBER"

# --- Test 8: 7z archives are extracted via 7z ---
echo ""
echo "=== Test 8: 7z archives ==="
T8="$TMPDIR/t8"
mkdir -p "$T8/sub"
stage="$(mktemp -d)"
printf 'hello' > "$stage/seven.txt"
7z a -t7z "$T8/sub/seven.7z" "$stage/seven.txt" > /dev/null
rm -rf "$stage"

pushd "$T8" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0 on 7z" "0" "$rc"
assert_file_exists "7z member extracted" "$T8/sub/seven/seven.txt"
assert_file_missing "7z original deleted" "$T8/sub/seven.7z"

# --- Test 9: multi-volume 7z extracted once, every part deleted ---
echo ""
echo "=== Test 9: multi-volume 7z ==="
T9="$TMPDIR/t9"
mkdir -p "$T9/sub"
stage="$(mktemp -d)"
head -c 300000 /dev/urandom > "$stage/big.bin"
7z a -t7z -v100k "$T9/sub/vol.7z" "$stage/big.bin" > /dev/null
rm -rf "$stage"

pushd "$T9" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0 on 7z volumes" "0" "$rc"
assert_file_exists "volumes extracted to base-name folder" "$T9/sub/vol/big.bin"
assert_file_missing "first volume deleted" "$T9/sub/vol.7z.001"
assert_file_missing "trailing volume deleted" "$T9/sub/vol.7z.003"

# --- Test 10: archive_rm deletes every multi-volume rar part, nothing else ---
echo ""
echo "=== Test 10: multi-volume rar cleanup ==="
T10="$TMPDIR/t10"
mkdir -p "$T10/sub"
for n in part01 part02 PART10; do printf 'x' > "$T10/sub/movie.$n.rar"; done
printf 'x' > "$T10/sub/movie.part1x.rar"
printf 'x' > "$T10/sub/other.part02.rar"

pushd "$T10" > /dev/null
archive_rm "./sub/movie.part01.rar"
popd > /dev/null

assert_file_missing "first part deleted"    "$T10/sub/movie.part01.rar"
assert_file_missing "second part deleted"   "$T10/sub/movie.part02.rar"
assert_file_missing "upper-case part deleted" "$T10/sub/movie.PART10.rar"
assert_file_exists  "non-volume name kept"  "$T10/sub/movie.part1x.rar"
assert_file_exists  "other archive kept"    "$T10/sub/other.part02.rar"

# --- Test 11: at the end, answering y opens File Explorer at every failed file ---
echo ""
echo "=== Test 11: open explorer on failure (y) ==="
T11="$TMPDIR/t11"
mkdir -p "$T11/sub"
printf 'not an archive at all' > "$T11/sub/broken.rar"
printf 'not an archive at all' > "$T11/sub/broken2.7z"
OPENED=()
open_in_explorer() { OPENED+=("$1"); }

pushd "$T11" > /dev/null
unzip_all_recursive > "$TMPDIR/t11.out" 2>&1 <<< "y"
rc=$?
popd > /dev/null
out="$(cat "$TMPDIR/t11.out")"

assert_eq "returns 1 after opening explorer" "1" "$rc"
assert_contains "asks whether to open explorer" "Open failed archive(s) in File Explorer? [y/N]" "$out"
assert_eq "explorer opened at each failed file" "./sub/broken.rar ./sub/broken2.7z" "${OPENED[*]}"

# --- Test 12: at the end, answering anything else does not open File Explorer ---
echo ""
echo "=== Test 12: open explorer on failure (n) ==="
OPENED=()
pushd "$T11" > /dev/null
unzip_all_recursive > /dev/null 2>&1 <<< "n"
rc=$?
popd > /dev/null

assert_eq "returns 1 when declined" "1" "$rc"
assert_eq "explorer not opened" "0" "${#OPENED[@]}"

# --- Test 13: archives produced by extraction are extracted too ---
echo ""
echo "=== Test 13: nested archives ==="
T13="$TMPDIR/t13"
mkdir -p "$T13"
stage="$(mktemp -d)"
make_zip "$stage/inner.zip" "inner.txt"
7z a -t7z "$stage/middle.7z" "$stage/inner.zip" > /dev/null
7z a -tzip "$T13/outer.zip" "$stage/middle.7z" > /dev/null
rm -rf "$stage"

pushd "$T13" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0 on nested archives" "0" "$rc"
assert_file_exists "innermost archive extracted" "$T13/outer/middle/inner/inner.txt"
assert_file_missing "middle archive deleted" "$T13/outer/middle.7z"
assert_file_missing "inner archive deleted" "$T13/outer/middle/inner.zip"
assert_contains "counts every level" "Done. 3 archive(s) extracted, 0 failed." "$out"

# --- Test 14: nested archives with originals kept are not extracted twice ---
echo ""
echo "=== Test 14: nested archives, keep originals ==="
T14="$TMPDIR/t14"
mkdir -p "$T14"
stage="$(mktemp -d)"
make_zip "$stage/inner.zip" "inner.txt"
7z a -tzip "$T14/outer.zip" "$stage/inner.zip" > /dev/null
rm -rf "$stage"

ELIT_DELETE_ORIGINAL=false
pushd "$T14" > /dev/null
out="$(unzip_all_recursive 2>&1)"
popd > /dev/null
ELIT_DELETE_ORIGINAL=true

assert_file_exists "inner extracted" "$T14/outer/inner/inner.txt"
assert_contains "each archive extracted once" "Done. 2 archive(s) extracted, 0 failed." "$out"

# --- Test 15: zip that zipfile cannot handle (Deflate64) falls back to 7z ---
echo ""
echo "=== Test 15: Deflate64 zip falls back to 7z ==="
T15="$TMPDIR/t15"
mkdir -p "$T15"
stage="$(mktemp -d)"
head -c 5000 /dev/zero > "$stage/d64.txt"   # too small a file gets Stored instead
7z a -tzip -mm=Deflate64 "$T15/d64.zip" "$stage/d64.txt" > /dev/null
rm -rf "$stage"

pushd "$T15" > /dev/null
out="$(unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0 on Deflate64 zip" "0" "$rc"
assert_contains "retried with 7z" "retrying with 7z" "$out"
assert_file_exists "Deflate64 member extracted" "$T15/d64/d64.txt"
assert_file_missing "Deflate64 original deleted" "$T15/d64.zip"

# --- Test 16: without uv in PATH, zip goes through 7z ---
echo ""
echo "=== Test 16: no uv ==="
T16="$TMPDIR/t16"
mkdir -p "$T16"
make_zip "$T16/plain.zip" "plain.txt"
# Drop every PATH entry that holds uv (copying tools into a bare PATH breaks on
# Git Bash: ln -s copies, and the copies can't find msys-2.0.dll)
NOUV_PATH=""
IFS=: read -ra path_dirs <<< "$PATH"
for d in "${path_dirs[@]}"; do
  [ -e "$d/uv" ] || [ -e "$d/uv.exe" ] || NOUV_PATH="${NOUV_PATH:+$NOUV_PATH:}$d"
done

pushd "$T16" > /dev/null
out="$(PATH="$NOUV_PATH"; command -v uv || echo "uv hidden"; unzip_all_recursive 2>&1)"
rc=$?
popd > /dev/null

assert_contains "uv hidden from PATH" "uv hidden" "$out"
assert_eq "returns 0 without uv" "0" "$rc"
assert_file_exists "zip extracted via 7z" "$T16/plain/plain.txt"

# --- Summary ---
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

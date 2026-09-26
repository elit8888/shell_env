#!/usr/bin/env bash
# Tests for mv_files_one_folder_up_renum (move a subfolder's contents up, renumbering files)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$SCRIPT_DIR/mv_files_one_folder_up_renum.sh"

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

assert_missing() {
  if [ ! -e "$2" ]; then pass "$1"; else fail "$1 — still exists: $2"; fi
}

# Names in the current directory, sorted, space-joined
listing() { ( cd "$1" && ls -A | sort | tr '\n' ' ' ); }

# --- Test 1: subfolder holding only directories (regression: rmdir on non-empty dir) ---
echo "=== Test 1: nested directories only ==="
T1="$TMPDIR/t1"
mkdir -p "$T1/a/b/c"
printf 'x' > "$T1/a/b/c/test.jpg"

pushd "$T1" > /dev/null
out="$("$SCRIPT" < /dev/null 2>&1)"
rc=$?
popd > /dev/null

assert_eq "returns 0" "0" "$rc"
assert_missing "source folder removed" "$T1/a"
assert_file_exists "nested tree moved up intact" "$T1/a-b/c/test.jpg"
[ "$rc" -eq 0 ] || echo "  output: $out"

# --- Test 2: plain files get renumbered ---
echo ""
echo "=== Test 2: files only ==="
T2="$TMPDIR/t2"
mkdir -p "$T2/a"
printf 'x' > "$T2/a/1.jpg"
printf 'x' > "$T2/a/2.jpg"
printf 'x' > "$T2/a/3.png"

pushd "$T2" > /dev/null
"$SCRIPT" < /dev/null > /dev/null 2>&1
rc=$?
popd > /dev/null

assert_eq "returns 0" "0" "$rc"
assert_eq "files renumbered by name order" "a-0.jpg a-1.jpg a-2.png " "$(listing "$T2")"

# --- Test 3: files and subfolders mixed ---
echo ""
echo "=== Test 3: files + subfolders ==="
T3="$TMPDIR/t3"
mkdir -p "$T3/a/sub"
printf 'x' > "$T3/a/sub/inner.txt"
printf 'x' > "$T3/a/1.jpg"
printf 'x' > "$T3/a/2.jpg"

pushd "$T3" > /dev/null
"$SCRIPT" < /dev/null > /dev/null 2>&1
rc=$?
popd > /dev/null

assert_eq "returns 0" "0" "$rc"
assert_eq "only files are numbered, folder keeps its name" "a-0.jpg a-1.jpg a-sub " "$(listing "$T3")"
assert_file_exists "subfolder content intact" "$T3/a-sub/inner.txt"
assert_missing "source folder removed" "$T3/a"

# --- Test 4: numbering is zero-padded to the file count ---
echo ""
echo "=== Test 4: zero padding ==="
T4="$TMPDIR/t4"
mkdir -p "$T4/a/sub"
for i in $(seq 1 10); do printf 'x' > "$T4/a/f$i.jpg"; done

pushd "$T4" > /dev/null
"$SCRIPT" < /dev/null > /dev/null 2>&1
popd > /dev/null

assert_file_exists "first file padded to 2 digits" "$T4/a-00.jpg"
assert_file_exists "last file padded to 2 digits" "$T4/a-09.jpg"
assert_eq "padding ignores the subfolder in the count" "10" "$(ls "$T4"/a-[0-9][0-9].jpg | wc -l)"

# --- Test 5: explicit directory argument ---
echo ""
echo "=== Test 5: explicit directory argument ==="
T5="$TMPDIR/t5"
mkdir -p "$T5/a/sub" "$T5/keep"
printf 'x' > "$T5/a/1.jpg"
printf 'x' > "$T5/keep/untouched.txt"

pushd "$T5" > /dev/null
"$SCRIPT" a < /dev/null > /dev/null 2>&1
rc=$?
popd > /dev/null

assert_eq "returns 0" "0" "$rc"
assert_eq "only the named directory is processed" "a-0.jpg a-sub keep " "$(listing "$T5")"
assert_file_exists "other folders untouched" "$T5/keep/untouched.txt"

# --- Summary ---
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && exit 0 || exit 1

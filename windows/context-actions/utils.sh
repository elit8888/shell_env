#!/usr/bin/env bash
# Shared utility functions for win-elit-utils scripts

# Set to "false" to keep original files after conversion
ELIT_DELETE_ORIGINAL="${ELIT_DELETE_ORIGINAL:-true}"

# --- Single-file converters ---

function gif2mp4_() {
  local f="$1"
  ffmpeg -y -v warning -i "$f" \
    -vf "scale=ceil(iw/2)*2:ceil(ih/2)*2,fps=30" \
    -c:v libx264 -pix_fmt yuv420p "${f%.*}.mp4"
}

function gif2webm_() {
  local f="$1"
  ffmpeg -y -v warning -i "$f" \
    -c:v libvpx-vp9 -b:v 0 -crf 32 -pix_fmt yuv420p "${f%.*}.webm"
}

function png2jpg_() {
  local f="$1"
  ffmpeg -y -v error -i "$f" "${f%.*}.jpg"
}

function webp2jpg_() {
  local f="$1"
  ffmpeg -y -v error -i "$f" "${f%.*}.jpg"
}

# --- Generic batch converter ---

function _batch_convert() {
  local ext="$1"
  local converter="$2"

  mapfile -d '' files < <(find . -type f -iname "*.$ext" -print0)

  if [ ${#files[@]} -eq 0 ]; then
    echo "No .$ext files found."
    return 1
  fi

  for f in "${files[@]}"; do
    echo "$f"
    if "$converter" "$f" && [ "$ELIT_DELETE_ORIGINAL" = true ]; then
      rm "$f"
    fi
  done
}

# --- Batch wrappers ---

function gif2mp4()  { _batch_convert gif  gif2mp4_;  }
function gif2webm() { _batch_convert gif  gif2webm_; }
function png2jpg()  { _batch_convert png  png2jpg_;  }
function webp2jpg() { _batch_convert webp webp2jpg_; }

function rpgmvp2png_() {
  local f="$1"
  local out="${2:-${f%.*}.png}"
  printf '\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52' > "$out"
  tail -c +33 "$f" >> "$out"
}

function rpgmvp2png() {
  mapfile -d '' files < <(find . -type f \( -iname "*.rpgmvp" -o -iname "*.png_" \) -print0)

  if [ ${#files[@]} -eq 0 ]; then
    echo "No .rpgmvp or .png_ files found."
    return 1
  fi

  for f in "${files[@]}"; do
    local rel="${f#./}"
    local out="./png/${rel%.*}.png"
    mkdir -p "$(dirname "$out")"
    echo "$f -> $out"
    if rpgmvp2png_ "$f" "$out" && [ "$ELIT_DELETE_ORIGINAL" = true ]; then
      rm "$f"
    fi
  done
}

function rename_large_ext() {
  local count=0
  while IFS= read -r -d '' f; do
    local new="${f%_large}"
    if [ -e "$new" ]; then
      echo "SKIP (exists): $new"
    else
      mv -- "$f" "$new"
      echo "Renamed: $f -> $new"
      (( count++ )) || true
    fi
  done < <(find . -type f \( -iname "*.jpg_large" -o -iname "*.png_large" \) -print0)

  echo
  echo "Done. $count file(s) renamed."
}

# --- Entry point for scripts ---

function elit_call() {
  local single_fn="$1"
  local batch_fn="$2"
  local file="$3"

  if [ -n "$file" ]; then
    echo "Converting single - $file"
    "$single_fn" "$file"
  else
    echo "Converting all"
    "$batch_fn"
  fi

  echo
  read -p "Press Enter to close..."
}

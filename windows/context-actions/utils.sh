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

  shopt -s nullglob
  local files=(*."$ext")
  shopt -u nullglob

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

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

# png / webp / jpeg -> jpg
function img2jpg_() {
  local f="$1"
  ffmpeg -y -v error -i "$f" "${f%.*}.jpg"
}

# --- Generic batch converter ---

# Usage: _batch_convert <converter> <ext>...
function _batch_convert() {
  local converter="$1"
  shift

  local expr=() ext
  for ext in "$@"; do
    [ ${#expr[@]} -gt 0 ] && expr+=(-o)
    expr+=(-iname "*.$ext")
  done

  local files=()
  mapfile -d '' files < <(find . -type f \( "${expr[@]}" \) -print0)

  if [ ${#files[@]} -eq 0 ]; then
    local exts=("${@/#/.}")
    local IFS=/
    echo "No ${exts[*]} files found."
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

function gif2mp4()  { _batch_convert gif2mp4_  gif; }
function gif2webm() { _batch_convert gif2webm_ gif; }
function img2jpg()  { _batch_convert img2jpg_  png webp jpeg; }

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

function scale_() {
  local fac="$1"
  local f="$2"
  local dir base
  dir="$(dirname "$f")"
  base="$(basename "$f")"
  mkdir -p "$dir/by${fac}"
  ffmpeg -y -v error -i "$f" -vf "scale=iw/${fac}:ih/${fac}" "$dir/by${fac}/$base"
}

function scale_all() {
  local fac="${1:-1}"
  mkdir -p "by${fac}"
  local found=false
  for f in *.jpg; do
    [ -e "$f" ] || continue
    found=true
    echo "$f"
    ffmpeg -y -v error -i "$f" -vf "scale=iw/${fac}:ih/${fac}" "by${fac}/$f"
  done
  [ "$found" = true ] || echo "No .jpg files found."
}

# Entry point for the scale action: <factor|more> [file]
function elit_scale() {
  local fac="$1"
  local file="$2"

  if [ "$fac" = "more" ]; then
    read -p "Enter scale factor (e.g. 2.5): " fac
  fi

  if [ -z "$fac" ]; then
    echo "No scale factor given."
  elif [ -n "$file" ]; then
    echo "Scaling single by $fac - $file"
    scale_ "$fac" "$file"
  else
    echo "Scaling all by $fac"
    scale_all "$fac"
  fi

  echo
  read -p "Press Enter to close..."
}

# 壓縮檔的解壓目的資料夾：去掉副檔名；分卷 7z（x.7z.001）去掉 .7z.001
function archive_out_dir() {
  local f="$1" out="${1%.*}"
  [[ "${f,,}" == *.7z.001 ]] && out="${out%.*}"
  echo "$out"
}

# 刪除壓縮檔；分卷 7z（x.7z.001）連同所有 x.7z.NNN、分卷 rar（x.partN.rar）連同所有 x.partN.rar 一起刪
function archive_rm() {
  local f="$1"
  local vol_re='^\.[Pp][Aa][Rr][Tt][0-9]+\.[Rr][Aa][Rr]$'
  if [[ "${f,,}" == *.7z.001 ]]; then
    rm -- "${f%.*}".[0-9][0-9][0-9]
  elif [[ "$f" =~ ^(.*)\.[Pp][Aa][Rr][Tt][0-9]+\.[Rr][Aa][Rr]$ ]]; then
    local base="${BASH_REMATCH[1]}" v
    for v in "$base".[Pp][Aa][Rr][Tt]*.[Rr][Aa][Rr]; do
      if [[ "${v:${#base}}" =~ $vol_re ]]; then rm -- "$v"; fi
    done
  else
    rm -- "$f"
  fi
}

# 遞迴解壓當前資料夾下所有 zip / rar / 7z，各自解到同名資料夾。
# zip 走 unzip_jp.py（UTF-8 / cp932 檔名偵測、加密檔問密碼），rar / 7z 走 7z。
# 一旦有檔案解壓失敗就停下來，讓使用者看得到是哪個檔案出問題。
function unzip_all_recursive() {
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local files=()
  mapfile -d '' files < <(find . -type f \( -iname "*.zip" -o -iname "*.rar" -o -iname "*.7z" -o -iname "*.7z.001" \) -print0 | sort -z)

  if [ ${#files[@]} -eq 0 ]; then
    echo "No .zip, .rar or .7z files found."
    return 0
  fi

  local count=0 f out
  for f in "${files[@]}"; do
    # 多分卷 rar 只解第一卷，其餘由 7z 自動接續
    if [[ "$f" =~ \.[Pp][Aa][Rr][Tt]([0-9]+)\.[Rr][Aa][Rr]$ ]] \
       && [ "$((10#${BASH_REMATCH[1]}))" -ne 1 ]; then
      echo "SKIP (multi-volume part): $f"
      continue
    fi

    out="$(archive_out_dir "$f")"
    [[ "$out" =~ ^(.*)\.[Pp][Aa][Rr][Tt][0-9]+$ ]] && out="${BASH_REMATCH[1]}"

    echo "Extracting: $f -> $out/"
    local rc=0
    case "${f,,}" in
      *.zip)
        if ! command -v python3 > /dev/null 2>&1; then
          echo "ERROR: python3 not found in PATH (needed for zip)."
          return 1
        fi
        python3 "$here/unzip_jp.py" "$f" "$out" || rc=$?
        ;;
      *.rar|*.7z|*.7z.001)
        if ! command -v 7z > /dev/null 2>&1; then
          echo "ERROR: 7z not found in PATH (needed for rar/7z)."
          return 1
        fi
        7z x -y -o"$out" "$f" || rc=$?
        ;;
    esac

    if [ "$rc" -ne 0 ]; then
      echo
      echo "ERROR: failed to extract: $f"
      echo "Stopped. $count archive(s) extracted before the failure."
      return 1
    fi

    [ "$ELIT_DELETE_ORIGINAL" = true ] && archive_rm "$f"
    (( count++ )) || true
  done

  echo
  echo "Done. $count archive(s) extracted."
  return 0
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

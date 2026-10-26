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

# Animated WebP: "VP8X" chunk at byte 12 with the animation flag (0x02) set at byte 20
function _is_animated_webp() {
  local hdr
  hdr=$(od -An -tx1 -N21 "$1" | tr -d ' \n')
  [ "${#hdr}" -eq 42 ] && [ "${hdr:24:8}" = 56503858 ] && (( 0x${hdr:40:2} & 0x02 ))
}

# png / webp / jpeg -> jpg (animated webp is skipped and reported as failure)
function img2jpg_() {
  local f="$1"
  if _is_animated_webp "$f"; then
    echo "skip animated: $f"
    return 1
  fi
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

  # Converter output (skips, ffmpeg warnings/errors) is collected and printed
  # after the progress list so it isn't buried among file names
  local msgs=() out
  for f in "${files[@]}"; do
    echo "$f"
    if out=$("$converter" "$f" 2>&1); then
      [ "$ELIT_DELETE_ORIGINAL" = true ] && rm "$f"
    fi
    [ -n "$out" ] && msgs+=("[$f]"$'\n'"$out")
  done

  if [ ${#msgs[@]} -gt 0 ]; then
    echo
    echo "=== Warnings / errors ==="
    printf '%s\n\n' "${msgs[@]}"
  fi
  return 0
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

# 在 File Explorer 開啟檔案所在資料夾並選取該檔（explorer.exe 結束碼恆非 0，故忽略）
function open_in_explorer() {
  explorer.exe /select,"$(cygpath -wa "$1")" || true
}

# 解壓單一壓縮檔到 $2。zip 先用 uv 跑 unzip_jp.py（UTF-8 / cp932 檔名偵測、加密檔問密碼），
# 沒有 uv 或解壓失敗（AES 加密、Deflate64 等 zipfile 不支援的格式）時改用 7z；rar / 7z 直接走 7z。
function unzip_one_() {
  local f="$1" out="$2" here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  if [[ "${f,,}" == *.zip ]] && command -v uv > /dev/null 2>&1; then
    uv run --script "$here/unzip_jp.py" "$f" "$out" && return 0
    echo "unzip_jp.py failed, retrying with 7z: $f"
  fi
  if ! command -v 7z > /dev/null 2>&1; then
    echo "ERROR: 7z not found in PATH."
    return 1
  fi
  7z x -y -o"$out" "$f"
}

# 遞迴解壓當前資料夾下所有 zip / rar / 7z，各自解到同名資料夾。
# 解出來的壓縮檔也會繼續解，直到沒有新的壓縮檔為止。
# 解壓失敗的檔案記下來並跳過；全部處理完後列出失敗清單，問使用者是否在 File Explorer 開啟。
function unzip_all_recursive() {
  local -A seen=()
  local failed=() count=0 found_any=false
  local files f out

  while true; do
    files=()
    mapfile -d '' files < <(find . -type f \( -iname "*.zip" -o -iname "*.rar" -o -iname "*.7z" -o -iname "*.7z.001" \) -print0 | sort -z)

    local new=()
    for f in "${files[@]}"; do
      [ -n "${seen[$f]+x}" ] || new+=("$f")
    done
    [ ${#new[@]} -eq 0 ] && break
    found_any=true

    for f in "${new[@]}"; do
      seen[$f]=1

      # 多分卷 rar 只解第一卷，其餘由 7z 自動接續
      if [[ "$f" =~ \.[Pp][Aa][Rr][Tt]([0-9]+)\.[Rr][Aa][Rr]$ ]] \
         && [ "$((10#${BASH_REMATCH[1]}))" -ne 1 ]; then
        echo "SKIP (multi-volume part): $f"
        continue
      fi

      out="$(archive_out_dir "$f")"
      [[ "$out" =~ ^(.*)\.[Pp][Aa][Rr][Tt][0-9]+$ ]] && out="${BASH_REMATCH[1]}"

      echo "Extracting: $f -> $out/"
      if unzip_one_ "$f" "$out"; then
        [ "$ELIT_DELETE_ORIGINAL" = true ] && archive_rm "$f"
        (( count++ )) || true
      else
        echo "ERROR: failed to extract: $f"
        failed+=("$f")
      fi
    done
  done

  if [ "$found_any" = false ]; then
    echo "No .zip, .rar or .7z files found."
    return 0
  fi

  echo
  echo "Done. $count archive(s) extracted, ${#failed[@]} failed."
  [ ${#failed[@]} -eq 0 ] && return 0

  echo "Failed:"
  printf '  %s\n' "${failed[@]}"
  local ans
  printf "Open failed archive(s) in File Explorer? [y/N] "
  read -r ans
  if [[ "${ans,,}" == y* ]]; then
    for f in "${failed[@]}"; do open_in_explorer "$f"; done
  fi
  return 1
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

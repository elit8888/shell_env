#!/usr/bin/env bash
# Recursively find all video files and move each one into a "video" subfolder
# inside its own parent directory.
# e.g., ./a/b/c/d.mp4 -> ./a/b/c/video/d.mp4
# Files already inside a "video" directory are skipped.

VIDEO_EXTS=(mp4 mkv avi mov wmv flv webm m4v mpg mpeg 3gp gif)

find_args=()
for ext in "${VIDEO_EXTS[@]}"; do
  if [ ${#find_args[@]} -gt 0 ]; then
    find_args+=(-o)
  fi
  find_args+=(-iname "*.$ext")
done

mapfile -d '' files < <(find . -type f \( "${find_args[@]}" \) -print0)

if [ ${#files[@]} -eq 0 ]; then
  echo "No video files found."
  read -p "Press Enter to close..."
  exit 0
fi

count=0
skipped=0
for f in "${files[@]}"; do
  dir="$(dirname "$f")"
  name="$(basename "$f")"

  # Skip files already inside a "video" directory
  if [[ "$dir" == */video || "$dir" == */video/* ]]; then
    (( skipped++ )) || true
    continue
  fi

  dest_dir="$dir/video"
  dest="$dest_dir/$name"

  mkdir -p "$dest_dir"

  if [ -e "$dest" ]; then
    echo "SKIP (exists): $dest"
  else
    mv -- "$f" "$dest"
    echo "Moved: $f -> $dest"
    (( count++ )) || true
  fi
done

echo
echo "Done. $count file(s) moved. $skipped already in video/ (skipped)."
read -p "Press Enter to close..."

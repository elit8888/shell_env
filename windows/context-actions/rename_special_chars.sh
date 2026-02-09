#!/usr/bin/env bash

function rename_special_chars() {
    shopt -s extglob

    # Depth-first so renaming a deep file doesn't break its parent path
    find . -depth -print0 | while IFS= read -r -d '' file; do
        [[ "$file" == "." ]] && continue

        dir=$(dirname "$file")
        base=$(basename "$file")

        # Replace one or more consecutive special chars with a single -
        newname="${base//+([　 ?'^+();,&＆、【】＋!^-])/-}"

        if [ "$base" != "$newname" ]; then
            newpath="$dir/$newname"
            if [ -e "$newpath" ]; then
                echo "Warning: $newpath already exists, skipping $file"
            else
                echo "Rename: $file -> $newpath"
                mv "$file" "$newpath"
            fi
        fi
    done

    shopt -u extglob
}

rename_special_chars
read -p "Press Enter to close..."

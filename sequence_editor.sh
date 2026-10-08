#!/bin/bash
todo_file="$1"
positions_to_edit=(1 3 4 15 16 19 23 24 25)
content=$(cat "$todo_file")
IFS=$'\n' read -d '' -r -a lines < <(printf '%s\n' "$content")
for i in "${!lines[@]}"; do
    line_num=$((i + 1))
    for pos in 1 3 4 15 16 19 23 24 25; do
        if [[ $((i + 1)) -eq $pos ]]; then
            lines[i]=$(echo "${lines[i]}" | sed -E 's/^pick /edit /')
            break
        fi
    done
done
printf '%s\n' "${lines[@]}" > "$todo_file"
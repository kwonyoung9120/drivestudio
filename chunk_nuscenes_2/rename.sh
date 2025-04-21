#!/bin/bash

new_idx=0

# 00부터 15까지 순회
for i in $(seq -w 0 15); do
    for j in 0 1; do
        old_name="chunk_${i}_${j}"
        new_name=$(printf "chunk_%02d" $new_idx)

        if [ -f "$old_name" ]; then
            mv "$old_name" "$new_name"
            echo "✅ Renamed $old_name → $new_name"
            new_idx=$((new_idx + 1))
        else
            echo "⚠️  $old_name 파일이 없습니다"
        fi
    done
done
#!/bin/bash

CONFIG_FILE=configs/omnire_extended_cam.yaml
OUTPUT_ROOT=/dataset/kwonyoung/drivestudio_results
PROJECT=nuscenes_preprocess
CHUNK_DIR=chunk_nuscenes_2

# 🎯 function to run a batch of 8 chunks
run_chunks() {
    for i in $(seq 0 7); do
        gpu_id=$i
        chunk_idx=$1  # 시작 인덱스: 0 또는 8
        chunk_file=$CHUNK_DIR/$(printf "chunk_%02d" $((chunk_idx + i)))

        {
            while read scene_idx; do
                run_name="nuscenes_$scene_idx"

                echo "🚀 [GPU $gpu_id] Starting scene $scene_idx"

                CUDA_VISIBLE_DEVICES=$gpu_id python tools/train.py \
                    --config_file $CONFIG_FILE \
                    --output_root $OUTPUT_ROOT \
                    --project $PROJECT \
                    --run_name $run_name \
                    dataset=nuscenes/6cams \
                    data.scene_idx=$scene_idx \
                    data.start_timestep=0 \
                    data.end_timestep=-1

                echo "✅ [GPU $gpu_id] Finished scene $scene_idx"
            done < $chunk_file
        } &
    done

    wait
}

# 🧠 1차 실행: chunk_00 ~ chunk_07
run_chunks 0

# 🧠 2차 실행: chunk_08 ~ chunk_15
#run_chunks 8

echo "🎉 All chunk jobs (chunk_00 ~ chunk_15) are completed!"
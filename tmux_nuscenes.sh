 
ENV_NAME="drivestudio"
# 설정
CONFIG_FILE=configs/omnire_extended_cam.yaml
OUTPUT_ROOT=/dataset/kwonyoung/drivestudio_results
PROJECT=nuscenes_preprocess
CHUNK_DIR=chunk_nuscenes_2
SESSION="nuscene"

TOTAL_THREADS=$(nproc)
THREADS_PER_JOB=4
# 1) 새로운 tmux 세션 생성 및 첫 윈도우(gpu0)
tmux -u new-session -d -s "$SESSION" -n "gpu0"
# 2) GPU1~GPU7용 윈도우 생성
gpus="1 2 3 4 5 6 7"
for gpu in $gpus; do
  tmux new-window -t "$SESSION" -n "gpu${gpu}"
done
# 3) 각 GPU 윈도우에 Conda 활성화 및 학습 스크립트 전송
all_gpus="0 1 2 3 4 5 6 7"
for gpu in $all_gpus; do
  window="gpu${gpu}"
  # 3.1) Conda 초기화 & 환경 활성화
  
  tmux send-keys -t "$SESSION:$window" "conda activate $ENV_NAME" C-m

  tmux send-keys -t "$SESSION:$window" "export OMP_NUM_THREADS=$THREADS_PER_JOB" C-m
  tmux send-keys -t "$SESSION:$window" "export MKL_NUM_THREADS=$THREADS_PER_JOB" C-m
  tmux send-keys -t "$SESSION:$window" "export OPENBLAS_NUM_THREADS=$THREADS_PER_JOB" C-m
  tmux send-keys -t "$SESSION:$window" "export NUMEXPR_NUM_THREADS=$THREADS_PER_JOB" C-m
  tmux send-keys -t "$SESSION:$window" "export VECLIB_MAXIMUM_THREADS=$THREADS_PER_JOB" C-m
  tmux send-keys -t "$SESSION:$window" "export TORCH_NUM_THREADS=$THREADS_PER_JOB" C-m
  
  # 3.2) PYTHONPATH 설정 (필요시)
  tmux send-keys -t "$SESSION:$window" "export PYTHONPATH=$(pwd)" C-m
  # 3.3) 학습 루프 송신
  tmux send-keys -t "$SESSION:$window" "for scene_idx in \$(cat $CHUNK_DIR/chunk_$(printf '%02d' $gpu)); do" C-m
  tmux send-keys -t "$SESSION:$window" "  run_name=\"nuscenes_\$scene_idx\"" C-m
  tmux send-keys -t "$SESSION:$window" "  echo \"🚀 [GPU $gpu] Starting scene \$scene_idx\"" C-m
  tmux send-keys -t "$SESSION:$window" "  CUDA_VISIBLE_DEVICES=$gpu python tools/train.py \
    --config_file $CONFIG_FILE \
    --output_root $OUTPUT_ROOT \
    --project $PROJECT \
    --run_name \$run_name \
    dataset=nuscenes/6cams \
    data.scene_idx=\$scene_idx \
    data.start_timestep=0 \
    data.end_timestep=-1" C-m
  tmux send-keys -t "$SESSION:$window" "  echo \"✅ [GPU $gpu] Finished scene \$scene_idx\"" C-m
  tmux send-keys -t "$SESSION:$window" "done" C-m
done

tmux new-window -t "$SESSION" -n "status"
window="status"
tmux send-keys -t "$SESSION:$window" "conda activate $ENV_NAME" C-m
tmux send-keys -t "$SESSION:$window" "nvitop" C-m

# 4) tmux 세션에 자동으로 연결
tmux -u attach -t "$SESSION"
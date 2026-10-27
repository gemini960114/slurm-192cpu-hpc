#!/bin/bash
#SBATCH --job-name=job_192cpus         # 工作名稱
#SBATCH --account=GOV113021            # 計畫專案帳號
#SBATCH --partition=dev                # 分割區 (短任務用 dev，長任務可用 8gpus 或 16gpus)
#SBATCH --nodes=2                      # 申請 2 個節點 (合計 192 核心)
#SBATCH --ntasks-per-node=1            # 每個節點 1 個主要任務
#SBATCH --cpus-per-task=96             # 每個任務 96 核心 (2 節點 × 96 = 192 核心)
#SBATCH --gpus-per-node=8              # 每個節點申請 8 張 H200 (滿足 1:12 CPU 比例配額)
#SBATCH --time=00:30:00                # 最長執行時間 (可依需求調整)
#SBATCH --output=logs/%x-%j.out            # 標準輸出日誌 (%x=工作名稱, %j=JobID)
#SBATCH --error=logs/%x-%j.err              # 標準錯誤日誌

echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Allocated Nodes: $SLURM_NODELIST"
echo "Allocated Total CPUs: $SLURM_JOB_CPUS_PER_NODE"
echo "Job started on $(date)"
echo "=========================================="

# 執行指令 (預設為 sleep 600，可替換為您的運算指令或訓練程式)
sleep 600

echo "Job finished on $(date)"

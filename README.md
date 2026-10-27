# slurm-192cpu-hpc

高效能運算 (HPC) 叢集之 Slurm 雙節點 192 核心作業提交範本與資源即時監控工具。

---

## 專案架構

```text
├── .gitignore          # 忽略日誌檔案，僅保留 logs/README.md
├── README.md           # 專案說明文件
├── check_res.sh        # Slurm 作業資源即時監控腳本 (Python)
├── run_192cpus.slurm   # 雙節點 192 核心 Slurm 批次作業範本
└── logs/               # 作業標準輸出與錯誤日誌存放目錄
    └── README.md
```

---

## 功能特色

- **雙節點平行運算 (192 CPUs / 16 GPUs)**：
  - 配置 2 節點 × 96 核心（合計 192 核心）與 16 張 GPU（每節點 8 張 H200），符合 1:12 之 CPU 配額比例。
  - 適用於大規模分散式訓練與高效能平行計算任務。
- **即時資源監控 (`check_res.sh`)**：
  - 動態抓取當前使用者 (`$USER`) 之作業狀態。
  - 一目了然呈現 JobID、作業狀態、節點數、GPU 張數、CPU 核心數、RAM (支援 TB 轉換) 與執行節點。

---

## 快速開始

### 1. 提交作業

```bash
sbatch run_192cpus.slurm
```

> **提示**：可直接編輯 `run_192cpus.slurm`，將內建的 `sleep 600` 替換為您的分散式訓練、MPI 或多行程運算指令。

### 2. 監控作業資源 (`check_res.sh`)

- **查看目前執行中 (RUNNING) 作業**：
  ```bash
  ./check_res.sh
  ```

- **查看今日所有歷史作業**：
  ```bash
  ./check_res.sh all
  ```

- **查看單一作業詳細資源配置**：
  ```bash
  ./check_res.sh <JobID>
  ```

---

## 日誌輸出

作業執行之標準輸出 (`.out`) 與錯誤日誌 (`.err`) 將自動存放於 `logs/` 目錄中，並由 `.gitignore` 自動忽略，避免不必要的 log 檔案上傳至版本控制。

#!/bin/bash
# =============================================================================
# Interactive GPU Session Script for Leonardo
# =============================================================================
# Use this script to get an interactive shell on a GPU node for debugging,
# testing evaluations, or exploring the container environment.
#
# Usage:
#   ./interactive_gpu.sh                       # Default: 1 hour, 1 GPU
#   ./interactive_gpu.sh 2                     # 2 hours, 1 GPU (positional)
#   ./interactive_gpu.sh 4 2                   # 4 hours, 2 GPUs (positional)
#   ./interactive_gpu.sh --hours 2 --gpus 4    # Named arguments
#   ./interactive_gpu.sh --cpus 16 --gpus 2    # Custom CPUs per task
#   ./interactive_gpu.sh --job-name debug_run  # Custom job name
# =============================================================================

set -euo pipefail

# Load environment (leonardo_env.sh is in the parent directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "${SCRIPT_DIR}")"
source "${REPO_DIR}/leonardo_env.sh"

# ── Defaults (from env or fallback) ──
HOURS=1
GPUS="${DEFAULT_GPUS:-1}"
CPUS=8
JOB_NAME="interactive_gpu"

# ── Parse arguments ──
# Support both positional (legacy) and named args
if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
    # Legacy positional: interactive_gpu.sh [HOURS] [GPUS]
    HOURS="${1:-1}"
    GPUS="${2:-${DEFAULT_GPUS:-1}}"
else
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --hours|-t)      HOURS="$2";    shift 2 ;;
            --gpus|-g)       GPUS="$2";     shift 2 ;;
            --cpus|-c)       CPUS="$2";     shift 2 ;;
            --job-name|-J)   JOB_NAME="$2"; shift 2 ;;
            -h|--help)
                echo "Usage: interactive_gpu.sh [HOURS] [GPUS]"
                echo "       interactive_gpu.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --hours, -t NUM    Session duration in hours (default: 1)"
                echo "  --gpus,  -g NUM    Number of GPUs (default: ${DEFAULT_GPUS:-1})"
                echo "  --cpus,  -c NUM    CPUs per task (default: 8)"
                echo "  --job-name, -J     Job name (default: interactive_gpu)"
                echo "  -h, --help         Show this help"
                echo ""
                echo "Positional (legacy):  interactive_gpu.sh 2 4  → 2 hours, 4 GPUs"
                exit 0
                ;;
            *) echo "Unknown option: $1. Use --help for usage."; exit 1 ;;
        esac
    done
fi

echo "=============================================="
echo "  Requesting Interactive GPU Session"
echo "=============================================="
echo "  Duration:  ${HOURS} hour(s)"
echo "  GPUs:      ${GPUS}"
echo "  CPUs:      ${CPUS}"
echo "  Job name:  ${JOB_NAME}"
echo "  Account:   ${ACCOUNT}"
echo "  Partition: ${PARTITION}"
echo "=============================================="

# Show queue estimate if squeue is available
if command -v squeue &>/dev/null; then
    _pending=$(squeue -u "${USER}" -t PENDING -h 2>/dev/null | wc -l)
    _running=$(squeue -u "${USER}" -t RUNNING -h 2>/dev/null | wc -l)
    echo "  Your jobs:  ${_running} running, ${_pending} pending"
    echo "=============================================="
fi
echo ""

# Request interactive session
srun --job-name="${JOB_NAME}" \
     --time="${HOURS}:00:00" \
     --nodes=1 \
     --ntasks-per-node=1 \
     --cpus-per-task="${CPUS}" \
     --gres=gpu:"${GPUS}" \
     --partition="${PARTITION}" \
     --account="${ACCOUNT}" \
     --pty bash

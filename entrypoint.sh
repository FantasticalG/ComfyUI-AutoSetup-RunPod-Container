#!/usr/bin/env bash
set -eo pipefail

# -----------------------------
# Config / defaults
# -----------------------------
# Setup repository (can be overwritten with SETUP_REPO) 
TARGET_REPO="${SETUP_REPO:-https://github.com/FantasticalG/ComfyUI-AutoSetup-Script}"
SETUP_DIR="/opt/setup"

# Install dir used by the setup scripts
export COMFY_DIR="${COMFY_DIR:-/workspace/ComfyUI}"

echo "Using setup repo: $TARGET_REPO"

# -----------------------------
# Pull latest setup scripts
# -----------------------------
# Clone or update the setup repo. SAFETY: never delete anything — if the path
# exists but is not a git repo and is not empty, abort instead of removing it.
if [[ -d "$SETUP_DIR/.git" ]]; then
    cd "$SETUP_DIR"
    git fetch && git pull
elif [[ -d "$SETUP_DIR" && -n "$(ls -A "$SETUP_DIR" 2>/dev/null)" ]]; then
    echo "[ERROR] '$SETUP_DIR' exists, is not a git repo, and is not empty — refusing to modify it."
    exit 1
else
    git clone "$TARGET_REPO" "$SETUP_DIR"
    cd "$SETUP_DIR"
fi

echo "[INFO] Running CUDA diagnostics..."
python "${SETUP_DIR}/scripts/helper/cuda_check.py" || true

# -----------------------------
# Update/Install unless skipped
# -----------------------------
if [[ "$SKIP_UPDATE" != "1" ]]; then
    echo "[INFO] Running install/update…"
    "${SETUP_DIR}/scripts/install_all.sh"  # run install/update
else
    echo "[INFO] SKIP_UPDATE=1 → skipping installation/update."
fi

# --- Function to start Jupyter Lab ---
start_jupyter() {
    echo "[INFO] Starting JupyterLab..."
    /opt/jupyter_venv/bin/jupyter lab \
        --ip=0.0.0.0 \
        --port=8888 \
        --allow-root \
        --no-browser \
        --ServerApp.root_dir=/workspace \
        --ServerApp.token='' \
        --ServerApp.password='' \
        --ServerApp.allow_origin='*' \
        --ServerApp.disable_check_xsrf=True \
        --ServerApp.allow_remote_access=True &
    JUPYTER_PID=$!
    echo "[INFO] JupyterLab PID = $JUPYTER_PID started on port 8888"
}

# --- Function to start ComfyUI ---
start_comfy() {
    echo "[INFO] Starting ComfyUI..."
    python "$COMFY_DIR/main.py" \
        --listen 0.0.0.0 \
        --port 8188 \
        --enable-cors-header '*' &  # bypass strict host/origin check so the RunPod proxy works (see README troubleshooting)
    COMFY_PID=$!
    echo "[INFO] ComfyUI PID = $COMFY_PID started on port 8188"
}

start_jupyter
start_comfy

# --- Trap kill signals and clean up both processes ---
cleanup() {
    echo "[INFO] Caught exit signal, shutting down..."
    kill $JUPYTER_PID 2>/dev/null || true
    kill $COMFY_PID 2>/dev/null || true
    wait
}
trap cleanup SIGTERM SIGINT

# --- Wait for both processes, exit if either dies ---
wait -n

echo "[ERROR] One of the services exited. Shutting down container."
cleanup
exit 1

#!/bin/bash
set -e

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
# Remove partial/broken setup folder
if [ -d "$SETUP_DIR" ] && [ ! -d "$SETUP_DIR/.git" ]; then
  log "[COMFYUI AUTO SETUP] Removing incomplete setup at $SETUP_DIR"
  rm -rf "$SETUP_DIR"
fi

# Clone or pull latest setup
if [ ! -d "$SETUP_DIR" ]; then
    git clone --depth 1 "$TARGET_REPO" "$SETUP_DIR"
    cd "$SETUP_DIR"
else
    cd "$SETUP_DIR"
    git fetch && git pull
fi

# -----------------------------
# Update/Install unless skipped
# -----------------------------
if [ "$SKIP_UPDATE" != "1" ]; then
    echo "[SETUP] Running install/update…"
    "${SETUP_DIR}/scripts/install_all.sh"  # run install/update
else
    echo "[SETUP] SKIP_UPDATE=1 → skipping installation/update."
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
        --port 8188 &
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

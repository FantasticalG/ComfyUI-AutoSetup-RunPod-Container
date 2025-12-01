# CUDA + cuDNN base recommended for RunPod
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04

# Minimal OS deps
RUN apt-get update && apt-get install -y \
    git curl wget python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# LibGL OpenCV dependency for VideoHelperSuite extension
RUN apt-get update && apt-get install -y libgl1 && rm -rf /var/lib/apt/lists/*

# Create venv for ComfyUI
RUN python3 -m venv /opt/comfy_venv --system-site-packages
ENV PATH="/opt/comfy_venv/bin:$PATH"

# Install Torch, index url is required for GPU support (CUDA)
RUN pip install --upgrade pip && \
    pip install torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu128

# Workspace (RunPod standard)
WORKDIR /workspace

# Create venv for JupyterLab
RUN python3 -m venv /opt/jupyter_venv --system-site-packages

# Upgrade pip inside venv 
RUN /opt/jupyter_venv/bin/python -m pip install --upgrade pip

# Install JupyterLabs
RUN /opt/jupyter_venv/bin/pip install --no-cache-dir jupyterlab

# Entrypoint
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

# Expose ComfyUI + JupyterLab
EXPOSE 8188 8888

ENTRYPOINT ["/opt/entrypoint.sh"]

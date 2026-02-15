# CUDA + cuDNN base recommended for RunPod
FROM nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04

# Minimal OS deps
RUN apt-get update && apt-get install -y \
    git curl wget python3.12 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/* 

# VideoHelperSuite extension dependencies
RUN apt-get update && apt-get install -y \
        libgl1 \
        libglib2.0-0 \
        ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Create venv for ComfyUI
RUN python3 -m venv /opt/comfy_venv --system-site-packages
ENV PATH="/opt/comfy_venv/bin:$PATH"

# Install Torch, index url is required for GPU support (CUDA)
RUN pip install --upgrade pip && \
    pip install torch torchvision torchaudio \
        --extra-index-url https://download.pytorch.org/whl/cu130

# Install sageattention flash_attn and triton (optional, 6% speed gain supported by e.g. SeedVR2 upscale)
RUN pip install sageattention
# pre-built flash-attn wheel from https://flashattn.dev/
RUN pip install https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.7.16/flash_attn-2.8.3%2Bcu130torch2.10-cp312-cp312-linux_x86_64.whl
RUN pip install triton 

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

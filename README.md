# ComfyUI-AutoSetup-RunPod-Container
Docker Container for ComfyUI Auto-Setup and JupiterLabs

## Overview
This Docker container is a lightweight Runpod wrapper for the [ComfyUI AutoSetup Script](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script).

- Automatic installation of ComfyUI, extensions, resources, and models (CivitAI + HuggingFace)
- Use the default [ComfyUI AutoSetup Script](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script) or adapt it to use your own set of extensions, models and workflows
- ComfyUI and extension versions are kept in sync using a given target date. The date of the last change in the setup script is the default.

This Docker environment provides:
- ComfyUI (port **8188**)
- JupyterLab (port **8888**)
- GPU acceleration via CUDA 12.8.1
- Fast builds with a minimal image
- Designed for RunPod

## Base Image
```
nvidia/cuda:12.8.1-cudnn-devel-ubuntu24.04
```
Chosen for stability and maximum GPU compatibility.

## Build the Image
```bash
docker build -t comfy-setup .
```

## Run Locally
```bash
docker run --gpus all \
  -p 8188:8188 -p 8888:8888 \
  -v ./data:/workspace \
  comfy-setup
```

## Environment Variables
| Variable | Description |
|---------|-------------|
| SETUP_REPO | Set to use your own setup with customized fork of the https://github.com/FantasticalG/ComfyUI-AutoSetup-Script |
| SKIP_UPDATE | Set `1` to skip install/update (faster boot, if already installed) |
| COMFY_DIR | Defaults to `/workspace/ComfyUI` |
| TARGET_DATE | Commit-date lock for deterministic installs |
| CIVITAI_API_KEY | Token for model downloads |
| HUGGINGFACE_API_KEY | Token for HuggingFace downloads |

## Notes
- All persistent data lives in `/workspace/ComfyUI`
- Automatic update happens unless `SKIP_UPDATE=1`
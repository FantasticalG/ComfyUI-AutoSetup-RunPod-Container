# ComfyUI-AutoSetup-RunPod-Container

Docker container for ComfyUI auto-setup and JupyterLab — a GPU-ready wrapper built for RunPod.

## Overview

This Docker container is a lightweight RunPod wrapper around the [ComfyUI AutoSetup Script](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script). On boot it clones that setup script, installs a complete ComfyUI environment, and serves ComfyUI alongside JupyterLab.

- Automatic installation of ComfyUI, extensions, resources, and models (CivitAI + HuggingFace).
- Use the default [setup script](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script) or point at your own fork to control which extensions, models, and workflows are installed.
- ComfyUI and extension versions are kept in sync via a target date (defaults to the latest commit in the setup script). See the setup script's [architecture docs](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script/blob/main/docs/architecture.md).

This environment provides:

- **ComfyUI** on port **8188**
- **JupyterLab** on port **8888**
- GPU acceleration via CUDA 13.0
- A minimal image for fast builds
- Designed for RunPod (works locally too)

## Prerequisites

- An NVIDIA GPU with up-to-date drivers.
- Docker with the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed (so `--gpus all` works).
- A HuggingFace and/or CivitAI API key if you want to download gated or CivitAI-hosted models.

## Build the image

```bash
docker build -t comfy-setup .
```

## Run locally

### With `docker run`

```bash
docker run --gpus all \
  -p 8188:8188 -p 8888:8888 \
  -v ./data:/workspace \
  -e HUGGINGFACE_API_KEY=hf_xxx \
  -e CIVITAI_API_KEY=xxxx \
  comfy-setup
```

### With Docker Compose

A [docker-compose.yaml](docker-compose.yaml) is included. It reserves all NVIDIA GPUs, maps both ports, and mounts `./data` as the persistent workspace. Provide your keys via the shell environment (or a `.env` file) and run:

```bash
export HUGGINGFACE_API_KEY=hf_xxx
export CIVITAI_API_KEY=xxxx
docker compose up --build
```

> **First boot is slow** — it downloads ComfyUI, extensions, and (potentially many GB of) models. Keep the workspace on a persistent volume and set `SKIP_UPDATE=1` on later runs to skip the install step.

## Environment variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SETUP_REPO` | Git URL of the setup script — set to use your own fork | `https://github.com/FantasticalG/ComfyUI-AutoSetup-Script` |
| `SKIP_UPDATE` | Set `1` to skip install/update (faster boot once everything is installed) | `0` |
| `COMFY_DIR` | ComfyUI installation directory | `/workspace/ComfyUI` |
| `TARGET_DATE` | Target date for deterministic installs (`yyyy-mm-dd`) | latest commit in the setup repo |
| `CIVITAI_API_KEY` | Token for CivitAI model downloads | not set |
| `HUGGINGFACE_API_KEY` | Token for HuggingFace downloads | not set |

## Accessing the services

- **ComfyUI** — port `8188`.
- **JupyterLab** — port `8888`, started with its root at `/workspace` and no token/password (rely on your network/RunPod access controls).

Both run in the background; if either exits, the container shuts down so the pod can restart cleanly.

> ⚠️ **Security warning — do not expose these ports to the public internet.**
> JupyterLab is started with **no token and no password** (`--ServerApp.token='' --ServerApp.password='' --ServerApp.allow_origin='*'`), and both services bind `0.0.0.0`. Anyone who can reach port **8888** gets arbitrary code execution (effectively root) on the GPU host, and port **8188** exposes the full ComfyUI API. This is only safe behind RunPod's authenticated proxy or a trusted private network. If you map these ports directly (e.g. local `docker run -p`, a public VPS), put them behind authentication / a firewall, or set a Jupyter token. See [docs/known-issues.md](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script/blob/main/docs/known-issues.md).

## Persistence

All installed data lives under `/workspace/ComfyUI`. Mounting a volume at `/workspace` (the `./data` bind mount above, or a RunPod network volume) preserves ComfyUI, extensions, and downloaded models across restarts. Combined with `SKIP_UPDATE=1`, restarts become near-instant.

## Using your own setup (custom fork)

Fork [ComfyUI-AutoSetup-Script](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script), adjust its `config/*.yaml` to your needs, and set `SETUP_REPO` to your fork's URL. The container will install from your fork instead of the default.

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| `torch.cuda.is_available: False` / no GPU | Missing `--gpus all` or NVIDIA Container Toolkit. Check the **CUDA DIAGNOSTICS** block printed at startup (from `cuda_check.py`). |
| Very slow startup | First boot installs everything. Use a persistent volume and set `SKIP_UPDATE=1` on later runs. |
| Models re-download every boot | The workspace isn't persisted — mount a volume at `/workspace`. |
| Gated / CivitAI model fails to download | Set `HUGGINGFACE_API_KEY` / `CIVITAI_API_KEY`. |

## Documentation

- [docs/runpod-deployment.md](docs/runpod-deployment.md) — RunPod platform deployment steps, boot sequence, and image internals.
- [Known issues & roadmap](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script/blob/main/docs/known-issues.md) — limitations and planned improvements (covers both repos).
- Setup script docs: [configuration](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script/blob/main/docs/configuration.md) · [architecture](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script/blob/main/docs/architecture.md) · [workflows](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script/blob/main/docs/workflows.md).

## License

See [LICENSE](LICENSE).

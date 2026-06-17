# RunPod Deployment & Image Internals

This document covers deploying the image on the [RunPod](https://www.runpod.io/) platform and what the image contains under the hood.

## Deploying on RunPod

The image is designed to run as a RunPod GPU pod.

1. **Publish the image.** Build and push to a registry RunPod can pull from (Docker Hub, GHCR, etc.):

   ```bash
   docker build -t <registry>/<you>/comfy-setup .
   docker push <registry>/<you>/comfy-setup
   ```

2. **Create a pod / template** pointing at that image, and:
   - **Expose HTTP ports** `8188` (ComfyUI) and `8888` (JupyterLab).
   - **Attach a persistent volume mounted at `/workspace`.** Everything the setup installs lives under `/workspace/ComfyUI`, so a volume here preserves ComfyUI, extensions, and downloaded models across pod restarts. Without it, every cold start re-downloads everything.
   - **Set environment variables** as needed (see the table in the [README](../README.md#environment-variables)). Most useful on RunPod:
     - `HUGGINGFACE_API_KEY` / `CIVITAI_API_KEY` — required for gated/CivitAI model downloads.
     - `SKIP_UPDATE=1` — skip the install/update step on subsequent boots once everything is in place (much faster startup).
     - `SETUP_REPO` — point at your own fork of the setup script to control which extensions/models/workflows get installed.
     - `TARGET_DATE` — pin a deterministic build date.

3. **First boot is slow.** The entrypoint clones the setup repo and runs the full install (ComfyUI + extensions + models). Expect a long first start while large models download. Subsequent boots with `SKIP_UPDATE=1` skip straight to launching the services.

4. **Access the services** via the proxied URLs RunPod assigns to ports 8188 and 8888. JupyterLab is started with no token/password and its root set to `/workspace`, so it is reachable directly behind RunPod's own access controls.

## Boot sequence

The container's [entrypoint.sh](../entrypoint.sh) runs on every start:

1. Clone or `git pull` the setup repo (`SETUP_REPO`) into `/opt/setup`.
2. Run CUDA diagnostics (`scripts/helper/cuda_check.py`) — printed to the container log.
3. Run `scripts/install_all.sh` unless `SKIP_UPDATE=1`.
4. Start JupyterLab (port 8888) and ComfyUI (port 8188) in the background.
5. `wait -n` — if either service exits, the container shuts the other down and exits, so the pod restarts cleanly.

## Image internals

Defined by the [Dockerfile](../Dockerfile):

- **Base:** `nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04`.
- **System packages:** `git`, `curl`, `wget`, Python 3.12 (+ `pip`, `venv`); plus `libgl1`, `libglib2.0-0`, and `ffmpeg` (required by VideoHelperSuite and video workflows).
- **Two virtualenvs:**
  - `/opt/comfy_venv` (on `PATH`) — runs ComfyUI. PyTorch is installed from the CUDA 13.0 wheel index (`--extra-index-url https://download.pytorch.org/whl/cu130`).
  - `/opt/jupyter_venv` — runs JupyterLab, isolated from the ComfyUI environment.
- **Optional speed-ups** (pre-installed): `sageattention`, a prebuilt `flash-attn` wheel, and `triton`. These provide a modest inference speed gain and are used by, e.g., the SeedVR2 upscaler.
- **Exposed ports:** `8188` and `8888`.
- **Entrypoint:** `/opt/entrypoint.sh`.

## Notes & gotchas

- **Relocating the install:** set `COMFY_DIR` (default `/workspace/ComfyUI`) — the entrypoint and the bundled [docker-compose.yaml](../docker-compose.yaml) both use this variable.
- Keep the install directory **on the persistent volume** (`/workspace/...`), otherwise `SKIP_UPDATE` has nothing to skip.
- Model download credentials are passed straight through to the setup script; see the script repo's [configuration docs](https://github.com/FantasticalG/ComfyUI-AutoSetup-Script/blob/main/docs/configuration.md#api-keys) for how keys are resolved.

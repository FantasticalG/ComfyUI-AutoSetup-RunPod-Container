# CLAUDE.md — ComfyUI-AutoSetup-RunPod-Container

Guidance for Claude Code working in this repo. Read this before making changes.

## What this repo is

A lightweight **Docker/RunPod wrapper** around the sibling repo
**ComfyUI-AutoSetup-Script**. On boot it clones that setup script, installs a full
ComfyUI environment, and serves **ComfyUI (port 8188)** + **JupyterLab (port 8888)**
on a CUDA/Linux GPU host. This is the **real deployment target** for the setup
script (which is otherwise only logic-tested on macOS).

## Safety rules (non-negotiable — a past mistake destroyed user data)

- **Never run destructive commands against live paths.** No `rm -rf`,
  `git clean -fdx`, `git checkout`/`reset` that discards work, or overwrite/move on
  project, home, or any real directory.
- **Never execute `entrypoint.sh` (or its clone/delete logic) to "verify" it.**
  Verify with `bash -n` and static reading only. Building/running the container is
  the user's call, not a verification step I run.
- **Confirm before any outward-facing or irreversible action.**

## Commits / version control

Make **working-tree edits only**. Do **not** commit, branch, or open PRs unless
explicitly asked — the user reviews and commits everything.

## Architecture & conventions

- **`Dockerfile`** — base `nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04`, Python 3.12,
  two venvs: `/opt/comfy_venv` (ComfyUI, with CUDA-13 PyTorch) and
  `/opt/jupyter_venv` (JupyterLab). Optional speed-ups: `sageattention`,
  prebuilt `flash-attn` wheel, `triton`. Note: the flash-attn wheel is pinned to a
  specific torch ABI while torch is unpinned — keep them consistent if you touch it.
- **`entrypoint.sh`** boot order: clone/update `/opt/setup` → CUDA diagnostics
  (`cuda_check.py`) → run `install_all.sh` unless `SKIP_UPDATE=1` → start JupyterLab
  + ComfyUI → `wait -n`. It does **not** source `lib_common.sh`, so it uses plain
  `echo` (not `log()`).
- **`docker-compose.yaml`** — uses **`COMFY_DIR`** (the entrypoint reads `COMFY_DIR`,
  **not** `INSTALL_DIR`). Default install dir `/workspace/ComfyUI`.
- **Env vars:** `SETUP_REPO` (use a fork), `SKIP_UPDATE` (skip install on reboot),
  `COMFY_DIR`, `TARGET_DATE`, `HUGGINGFACE_API_KEY`, `CIVITAI_API_KEY`, `SKIP_MODELS`,
  `COMFY_ARGS`.
- ComfyUI launches with `--listen 0.0.0.0 --port 8188 --enable-cors-header '*'` plus
  `$COMFY_ARGS` (unquoted on purpose → word-splits into flags).
- **RunPod proxy URLs are public** (not gated by login) — don't describe them as
  authenticated. JupyterLab runs with no token by default; only persistent data
  under `/workspace` survives restarts.

## Coding style

**Bash** — lint with `shellcheck`, format with `shfmt`:
- `#!/usr/bin/env bash` + `set -eo pipefail`; 2-space indentation; `[[ … ]]` for
  tests (not `[ … ]`); always quote expansions; `$(…)` not backticks; snake_case.
- Use plain `echo "[INFO] …"` for messages here — this script does **not** source
  `lib_common.sh`, so there is no `log()`. Keep the `# ---` section headers.
- Keep the image minimal; document any new system/pip dependency in `README.md`.

## Verification & docs

- Shell/Dockerfile changes: `bash -n` (and `shellcheck` if available) + static
  reasoning. Don't build/run the image as a verification step.
- Keep `README.md` and `docs/runpod-deployment.md` in sync with behavior — but
  **ask before large README rewrites**. The cross-repo known-issues list lives in
  the setup-script repo's `docs/known-issues.md`.

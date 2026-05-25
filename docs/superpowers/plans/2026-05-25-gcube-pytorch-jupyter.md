# gcube PyTorch + JupyterLab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a private GitHub repo that publishes a PyTorch + JupyterLab image to GHCR and deploys it to gcube as a workload.

**Architecture:** Keep the project intentionally small: one container definition, one GitHub Actions workflow, one deployment manifest, and one README that explains the operational steps. The runtime contract is only `JUPYTER_TOKEN`, while all other behavior stays fixed in the image and workload configuration.

**Tech Stack:** Docker, GitHub Actions, GHCR, gcube CLI, PyTorch base image, JupyterLab

---

## File Structure

- Create: `Dockerfile`
- Create: `.github/workflows/build.yml`
- Create: `README.md`
- Create: `workload.yaml`
- Create: `.dockerignore`
- Create: `docs/superpowers/specs/2026-05-25-gcube-pytorch-jupyter-design.md`

## Task 1: Initialize the GitHub Repository

**Files:**
- Create: `.git/` via `git init`
- Create: remote GitHub repository `vfxceo-ai/gcube-pytorch-jupyter`

- [ ] **Step 1: Initialize the local Git repository**

Run:

```powershell
git init
git branch -M main
```

Expected: `.git` directory exists and `git branch --show-current` prints `main`.

- [ ] **Step 2: Create the private GitHub repository**

Run:

```powershell
gh repo create vfxceo-ai/gcube-pytorch-jupyter --private --source . --remote origin --push
```

Expected: GitHub prints the new repository URL and configures `origin`.

- [ ] **Step 3: Verify remote wiring**

Run:

```powershell
git remote -v
gh repo view vfxceo-ai/gcube-pytorch-jupyter --json name,visibility,owner
```

Expected: `origin` points at `vfxceo-ai/gcube-pytorch-jupyter` and visibility is `PRIVATE`.

- [ ] **Step 4: Commit repository bootstrap state**

Run:

```powershell
git add docs/superpowers/specs/2026-05-25-gcube-pytorch-jupyter-design.md docs/superpowers/plans/2026-05-25-gcube-pytorch-jupyter.md
git commit -m "docs: add deployment design and implementation plan"
git push -u origin main
```

Expected: initial documentation commit exists on `main`.

## Task 2: Author the Container Image

**Files:**
- Create: `Dockerfile`
- Create: `.dockerignore`

- [ ] **Step 1: Write the Dockerfile**

Create `Dockerfile` with:

```dockerfile
FROM pytorch/pytorch:2.7.0-cuda12.8-cudnn9-runtime

WORKDIR /workspace

RUN pip install --no-cache-dir \
    jupyterlab \
    numpy \
    pandas \
    matplotlib \
    transformers \
    datasets

EXPOSE 8888

CMD ["bash", "-lc", "if [ -n \"$JUPYTER_TOKEN\" ]; then exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --ServerApp.token=\"$JUPYTER_TOKEN\"; else exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --ServerApp.token=''; fi"]
```

- [ ] **Step 2: Write `.dockerignore`**

Create `.dockerignore` with:

```gitignore
.git
.github
docs
__pycache__
*.pyc
*.pyo
*.pyd
```

- [ ] **Step 3: Build the image locally to verify syntax**

Run:

```powershell
docker build -t gcube-pytorch-jupyter:local .
```

Expected: image builds successfully without Dockerfile parse or package install errors.

- [ ] **Step 4: Smoke-test the Jupyter startup contract**

Run:

```powershell
docker run --rm -p 8888:8888 gcube-pytorch-jupyter:local
```

Expected: logs show Jupyter listening on `0.0.0.0:8888`.

- [ ] **Step 5: Commit the container definition**

Run:

```powershell
git add Dockerfile .dockerignore
git commit -m "feat: add pytorch jupyter container image"
git push
```

Expected: container definition is stored on `main`.

## Task 3: Add GitHub Actions for GHCR Publishing

**Files:**
- Create: `.github/workflows/build.yml`

- [ ] **Step 1: Write the workflow**

Create `.github/workflows/build.yml` with:

```yaml
name: Build and Push Image

on:
  push:
    branches:
      - main

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: vfxceo-ai/gcube-pytorch-jupyter

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push image
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
```

- [ ] **Step 2: Push the workflow and wait for CI**

Run:

```powershell
git add .github/workflows/build.yml
git commit -m "ci: publish image to ghcr"
git push
gh run list --repo vfxceo-ai/gcube-pytorch-jupyter --limit 1
```

Expected: latest workflow run appears for the `main` branch push.

- [ ] **Step 3: Inspect the workflow result**

Run:

```powershell
gh run watch --repo vfxceo-ai/gcube-pytorch-jupyter
gh run view --repo vfxceo-ai/gcube-pytorch-jupyter --log
```

Expected: workflow completes successfully and the push step finishes without auth errors.

- [ ] **Step 4: Verify the GHCR package exists**

Run:

```powershell
gh api /users/vfxceo-ai/packages/container/gcube-pytorch-jupyter/versions
```

Expected: API returns at least one package version entry.

## Task 4: Document Usage and Deployment Preconditions

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write the README**

Create `README.md` with:

```markdown
# gcube-pytorch-jupyter

PyTorch + JupyterLab environment for gcube.

## Image

- Base image: `pytorch/pytorch:2.7.0-cuda12.8-cudnn9-runtime`
- Published image: `ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest`

## Included Packages

- jupyterlab
- numpy
- pandas
- matplotlib
- transformers
- datasets

## Runtime

- Port: `8888`
- Workdir: `/workspace`
- Optional env: `JUPYTER_TOKEN`

If `JUPYTER_TOKEN` is empty, JupyterLab starts without token authentication.

## Deployment Notes

- The repository and GHCR package are private.
- gcube must have a GHCR-capable credential before pulling the image.
- `/workspace` is the default working directory, but this first version does not configure durable external storage.
```

- [ ] **Step 2: Commit the README**

Run:

```powershell
git add README.md
git commit -m "docs: add project readme"
git push
```

Expected: README is visible in the GitHub repository root.

## Task 5: Author the gcube Workload Manifest

**Files:**
- Create: `workload.yaml`

- [ ] **Step 1: Write the workload manifest**

Create `workload.yaml` with:

```yaml
description: gcube-pytorch-jupyter
containerImage: ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest
repo: ghcr.io
port: 8888
gpuCode: 101
cuda: 12080
sharedMemory: 4
containerEnvs:
  - key: JUPYTER_TOKEN
    value: ""
```

- [ ] **Step 2: Review the manifest before registration**

Run:

```powershell
Get-Content workload.yaml
```

Expected: image, repo, port, GPU, CUDA, and `JUPYTER_TOKEN` fields match the approved design.

- [ ] **Step 3: Commit the workload manifest**

Run:

```powershell
git add workload.yaml
git commit -m "feat: add gcube workload manifest"
git push
```

Expected: workload manifest is versioned in the repo.

## Task 6: Prepare Private GHCR Pull Access for gcube

**Files:**
- Modify: gcube credential store outside repo

- [ ] **Step 1: Check current gcube credentials**

Run:

```powershell
gcube credential list
```

Expected: confirms whether a `ghcr.io` or GitHub-oriented credential already exists.

- [ ] **Step 2: Add GHCR pull credential if missing**

Run:

```powershell
gcube credential add
```

Expected: interactive flow completes with GitHub username and a token that can read the private GHCR package.

- [ ] **Step 3: Re-verify credential registration**

Run:

```powershell
gcube credential list
```

Expected: output now includes the credential that gcube will use for `ghcr.io`.

## Task 7: Register and Start the Workload

**Files:**
- Use: `workload.yaml`

- [ ] **Step 1: Register the workload**

Run:

```powershell
gcube workload register -f workload.yaml
```

Expected: command returns a new workload `SER` identifier.

- [ ] **Step 2: Start the workload**

Run:

```powershell
gcube workload start <SER>
```

Expected: gcube accepts the start request without schema or image errors.

- [ ] **Step 3: Poll deployment state**

Run:

```powershell
gcube workload describe <SER>
```

Expected: state transitions toward deployed status and exposes service details.

- [ ] **Step 4: Re-check after 1-2 minutes if not yet deployed**

Run:

```powershell
gcube workload describe <SER>
```

Expected: state becomes `deploy`.

## Task 8: Final Verification and Handoff

**Files:**
- No new files

- [ ] **Step 1: Confirm GitHub Actions success one last time**

Run:

```powershell
gh run list --repo vfxceo-ai/gcube-pytorch-jupyter --limit 3
```

Expected: latest `Build and Push Image` run is `completed` and `success`.

- [ ] **Step 2: Confirm workload deployment state**

Run:

```powershell
gcube workload describe <SER>
```

Expected: workload state is `deploy`.

- [ ] **Step 3: Hand off runtime details to the user**

Report:

```text
SER: <SER>
Image: ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest
Port: 8888
Token source: containerEnvs.JUPYTER_TOKEN
User checks in gcube console: SSH info, service URL
```

- [ ] **Step 4: Commit any final docs-only adjustments if needed**

Run:

```powershell
git status --short
```

Expected: working tree is clean, or only intentional documentation follow-ups remain.

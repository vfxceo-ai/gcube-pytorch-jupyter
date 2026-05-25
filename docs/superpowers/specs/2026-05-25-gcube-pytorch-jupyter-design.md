# gcube PyTorch + JupyterLab Deployment Design

## Goal

Create a private GitHub repository `vfxceo-ai/gcube-pytorch-jupyter`, build a PyTorch + JupyterLab container image with GitHub Actions, publish it to `ghcr.io`, and deploy it as a gcube workload.

## Confirmed Decisions

- Service: PyTorch + JupyterLab
- Primary use: development and experimentation notebook environment
- Base image: `pytorch/pytorch:2.7.0-cuda12.8-cudnn9-runtime`
- Extra Python packages:
  - `jupyterlab`
  - `numpy`
  - `pandas`
  - `matplotlib`
  - `transformers`
  - `datasets`
- Working directory: `/workspace`
- Port: `8888`
- GitHub repository visibility: `private`
- Container registry target: `ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest`
- GPU selection: `gpuCode: 101`
- CUDA code in workload: `12080`
- Shared memory: `4`
- User-configurable runtime variable: `JUPYTER_TOKEN`
- Model and dataset content: not baked into the image; user will fetch later
- Storage approach for now: use `/workspace` inside the workload without external storage mount

## Architecture

The deliverable consists of four repo-managed artifacts:

1. `Dockerfile`
2. `.github/workflows/build.yml`
3. `README.md`
4. `workload.yaml`

The repository acts as the source of truth for both image creation and gcube deployment. A push to `main` triggers GitHub Actions, which builds the container and pushes `latest` to `ghcr.io`. gcube then pulls that private image and starts a workload exposing JupyterLab on port `8888`.

## Runtime Design

The image starts JupyterLab bound to `0.0.0.0:8888` with `--no-browser`.

Token behavior:

- If `JUPYTER_TOKEN` is set, start Jupyter with that token.
- If `JUPYTER_TOKEN` is unset or empty, start Jupyter with token authentication disabled.

This keeps the runtime contract small and allows the user to change only one deployment-time secret through `containerEnvs`.

## Data Handling

The initial deployment will use `/workspace` as the working path with no external mounted storage.

Implications:

- This is sufficient for a first-pass interactive notebook environment.
- It does not guarantee durable persistence across workload recreation or image replacement.
- Persistent storage is intentionally deferred to a later iteration so the first deployment stays narrow and verifiable.

## Registry and Credential Design

Both the GitHub repository and the image remain private.

Because the image is hosted in private GHCR, gcube must have a GitHub credential capable of pulling from `ghcr.io`. Existing gcube credentials currently show only a `docker` repo entry, so a GHCR-compatible credential must be added before workload deployment.

GitHub Actions will push with the repository `GITHUB_TOKEN` and `packages: write` permission, which is supported for publishing packages associated with the workflow repository.

## Deployment Flow

1. Create repository `vfxceo-ai/gcube-pytorch-jupyter` as private.
2. Add source files and push initial commit to `main`.
3. Wait for GitHub Actions to build and publish `ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest`.
4. Confirm the image exists and the workflow completed successfully.
5. Add or confirm gcube GHCR credential for private image pulls.
6. Register `workload.yaml` with `gcube workload register -f workload.yaml`.
7. Start the workload with `gcube workload start <ser>`.
8. Confirm deployment state using `gcube workload describe <ser>`.

## Workload Design

The workload definition will include:

- `description: gcube-pytorch-jupyter`
- `containerImage: ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest`
- `repo: ghcr.io`
- `port: 8888`
- `gpuCode: 101`
- `cuda: 12080`
- `sharedMemory: 4`
- `containerEnvs` containing `JUPYTER_TOKEN`

No model bootstrap, dataset preload, or storage mount will be included in the first version.

## Error Handling

- If GitHub Actions fails, stop before gcube registration and fix the image build first.
- If GHCR push succeeds but gcube cannot pull the image, verify GHCR credential registration in gcube.
- If the workload starts but Jupyter does not respond, inspect workload details and container logs before modifying the spec.

## Verification

Success requires all of the following:

1. GitHub Actions build completes successfully.
2. `ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest` exists.
3. `gcube workload describe <ser>` reports the workload in deployed state.
4. gcube console shows SSH information and the service URL for the user to inspect.

## Out of Scope

- External persistent storage configuration
- Preinstalled project notebooks, models, or datasets
- Multi-user authentication beyond Jupyter token behavior
- Automatic package version pinning beyond the specified base image

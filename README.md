# gcube-pytorch-jupyter

PyTorch + JupyterLab runtime for gcube deployments.

## Image

- Base image: `pytorch/pytorch:2.7.0-cuda12.8-cudnn9-runtime`
- Published image: `ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest`
- Source repository: `https://github.com/vfxceo-ai/gcube-pytorch-jupyter`
- Repository/package policy: private GitHub repo, private GHCR package

## Included Packages

The image installs the following Python packages on top of the PyTorch base image:

- `jupyterlab`
- `numpy`
- `pandas`
- `matplotlib`
- `transformers`
- `datasets`

## Runtime Settings

- Working directory: `/workspace`
- Exposed port: `8888`
- Default process: JupyterLab bound to `0.0.0.0:8888`
- Browser launch: disabled with `--no-browser`
- Token handling:
  - If `JUPYTER_TOKEN` is set, JupyterLab uses that value.
  - If `JUPYTER_TOKEN` is unset, JupyterLab starts without a token.

The container starts JupyterLab with `--allow-root` because the current image runs the notebook server as root.

## Build and Publish

GitHub Actions builds and pushes the image on every push to `main`.

- Workflow file: `.github/workflows/build.yml`
- Registry: `ghcr.io`
- Tag: `ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest`

## Deployment Notes

- Target platform: gcube workload
- Service port: `8888`
- Expected workspace path inside the container: `/workspace`
- v1 does not attach durable external storage. Data written inside the container should be treated as ephemeral.
- Because the image is stored in a private GHCR package, gcube must have GitHub credentials that can pull from `ghcr.io/vfxceo-ai/gcube-pytorch-jupyter`.
- When exposing Jupyter externally, set `JUPYTER_TOKEN` unless the deployment is already protected by a trusted private access boundary.

## Example Local Run

Without a token:

```bash
docker run --rm -p 8888:8888 ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest
```

With a token:

```bash
docker run --rm -p 8888:8888 -e JUPYTER_TOKEN=my-token ghcr.io/vfxceo-ai/gcube-pytorch-jupyter:latest
```

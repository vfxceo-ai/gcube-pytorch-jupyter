FROM pytorch/pytorch:2.7.0-cuda12.8-cudnn9-runtime

WORKDIR /workspace

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN pip install --no-cache-dir \
    jupyterlab \
    numpy \
    pandas \
    matplotlib \
    transformers \
    datasets

EXPOSE 8888

CMD ["sh", "-c", "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token=\"${JUPYTER_TOKEN:-}\" --ServerApp.password=\"\" --ServerApp.root_dir=/workspace"]

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

CMD ["bash", "-lc", "if [ -n \"$JUPYTER_TOKEN\" ]; then exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --IdentityProvider.token=\"$JUPYTER_TOKEN\"; else exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --IdentityProvider.token=''; fi"]

FROM nvidia/cuda:13.3.0-base-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    python3 \
    python3-dev \
    git libgl1 libglib2.0-0 \
    gcc \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# ComfyUI's own code is small — keep it baked into the image, versioned by
# git tag. torch/torchvision/torchaudio and ComfyUI's requirements.txt are
# NOT installed here: they're multi-GB and get installed once into a
# volume-mounted venv by entrypoint.sh instead, keeping this image thin.
WORKDIR /opt
RUN git clone --depth 1 --branch v0.26.0 https://github.com/Comfy-Org/ComfyUI ComfyUI

# Always exists in the image itself, mount or no mount — running the image
# directly without -v /opt/venv (e.g. a quick `docker run` smoke test) would
# otherwise hit entrypoint.sh's `find /opt/venv` against a missing directory.
RUN mkdir -p /opt/venv

RUN mkdir -p /opt/ComfyUI/user/default/workflows
COPY workflows/ /opt/ComfyUI/user/default/workflows/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /opt/ComfyUI
EXPOSE 8188
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--listen", "0.0.0.0", "--port", "8188"]

FROM nvidia/cuda:13.3.0-base-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    python3 \
    git libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN uv pip install --system --break-system-packages --no-cache \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu130

WORKDIR /opt
RUN git clone --depth 1 --branch v0.26.0 https://github.com/Comfy-Org/ComfyUI ComfyUI \
    && cd ComfyUI && uv pip install --system --break-system-packages --no-cache -r requirements.txt

RUN mkdir -p /opt/ComfyUI/user/default/workflows
COPY workflows/ /opt/ComfyUI/user/default/workflows/

WORKDIR /opt/ComfyUI
EXPOSE 8188
ENTRYPOINT ["python3", "main.py"]
CMD ["--listen", "0.0.0.0", "--port", "8188"]

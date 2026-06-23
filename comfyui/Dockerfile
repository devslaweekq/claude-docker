FROM nvidia/cuda:13.3.0-base-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y \
    python3 python3-pip \
    git libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages \
    torch torchvision torchaudio \
    --index-url https://download.pytorch.org/whl/cu130

WORKDIR /opt
RUN git clone https://github.com/Comfy-Org/ComfyUI ComfyUI \
    && cd ComfyUI && pip3 install --no-cache-dir --break-system-packages -r requirements.txt

RUN mkdir -p /opt/ComfyUI/user/default/workflows
COPY workflows/default.json /opt/ComfyUI/user/default/workflows/

WORKDIR /opt/ComfyUI
EXPOSE 8188
ENTRYPOINT ["python3", "main.py"]
CMD ["--listen", "0.0.0.0", "--port", "8188"]
